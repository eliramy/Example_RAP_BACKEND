CLASS ltcl_books DEFINITION DEFERRED FOR TESTING.
CLASS lhc_Books DEFINITION INHERITING FROM cl_abap_behavior_handler FRIENDS ltcl_books.
  PRIVATE SECTION.

    METHODS finishBook FOR MODIFY
      IMPORTING keys FOR ACTION Books~finishBook.
    METHODS validateISBN FOR VALIDATE ON SAVE
      IMPORTING keys FOR Books~validateISBN.
    METHODS determineNote FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Books~determineNote.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Books RESULT result.

ENDCLASS.

CLASS lhc_Books IMPLEMENTATION.

  METHOD finishBook.
    READ ENTITY IN LOCAL MODE zrap_iv_books
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_books).



    LOOP AT lt_books ASSIGNING FIELD-SYMBOL(<fs_book>).

      IF <fs_book>-ReadingFinished = abap_true.

        APPEND VALUE #( %tky = <fs_book>-%tky
                        %msg = NEW zcm_rap(
                                  textid   = zcm_rap=>already_finished
                                  severity = if_abap_behv_message=>severity-error
                               )
                      )
           TO reported-books.

      ELSE.

        MODIFY ENTITY IN LOCAL MODE zrap_iv_books
           UPDATE FIELDS (  ReadingFinished )
                    WITH VALUE #(
                                  ( %tky = <fs_book>-%tky
                                    ReadingFinished = abap_true
                                  )
                                )
           FAILED DATA(ls_failed).

        IF ls_failed IS INITIAL.

          APPEND VALUE #( %tky = <fs_book>-%tky
                          %msg = NEW zcm_rap(
                                   textid   = zcm_rap=>book_finished
                                   severity = if_abap_behv_message=>severity-success
                                 )
                        )
            TO reported-books.

        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateISBN.
    READ ENTITY IN LOCAL MODE zrap_iv_books
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_books).

    LOOP AT lt_books ASSIGNING FIELD-SYMBOL(<fs_book>).
      IF strlen( <fs_book>-isbn ) NOT BETWEEN 10 AND 13.
        APPEND CORRESPONDING #( <fs_book> ) TO failed-books.

        APPEND VALUE #(
           %tky     = <fs_book>-%tky
           %element = VALUE #( isbn = if_abap_behv=>mk-on )
           %msg     = NEW zcm_rap(
                        textid     = zcm_rap=>isbn_validation_failed
                        severity   = if_abap_behv_message=>severity-error
                                  )
           %state_area = 'ISBN'
                      )
             TO reported-books.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determineNote.
        MODIFY ENTITY IN LOCAL MODE zrap_iv_books
        UPDATE FIELDS ( Note )
        WITH VALUE #( FOR key IN keys (
          %tky = key-%tky
          Note = 'Provide some notes'
        ) ) REPORTED DATA(ls_reported).

        reported = CORRESPONDING #( DEEP ls_reported ).

  ENDMETHOD.

  METHOD get_instance_features.
    DATA ls_result LIKE LINE OF result.

    CONSTANTS c_enabled   TYPE if_abap_behv=>t_xflag
                         VALUE if_abap_behv=>fc-o-enabled.
    CONSTANTS c_disabled  TYPE if_abap_behv=>t_xflag
                         VALUE if_abap_behv=>fc-o-disabled.
    CONSTANTS c_mandatory TYPE if_abap_behv=>t_xflag
                         VALUE if_abap_behv=>fc-f-mandatory.

    READ ENTITY IN LOCAL MODE zrap_iv_books
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_books).

    LOOP AT lt_books ASSIGNING FIELD-SYMBOL(<fs_book>).
        CLEAR ls_result.

        ls_result-%tky = <fs_book>-%tky.

        IF <fs_book>-ReadingFinished = abap_true.
            ls_result-%features-%action-finishBook = c_disabled.
            ls_result-%features-%update = c_disabled.
        ELSE.
            ls_result-%features-%action-finishBook = c_enabled.
            ls_result-%features-%update = c_enabled.
        ENDIF.

        IF <fs_book>-Author IS NOT INITIAL.
            ls_result-%features-%field-Genre = c_mandatory.
        ENDIF.

        APPEND ls_result TO result.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS ltcl_Books DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA:
              lo_environment TYPE REF TO if_cds_test_environment,
              lo_environment_data_base TYPE REF TO if_osql_test_environment,
              lt_books_mock TYPE STANDARD TABLE OF zrap_books.
    DATA:
        lo_cut TYPE REF TO lhc_books.

    CLASS-METHODS:
        class_setup,
        class_teardown.
    METHODS:
      test_demo FOR TESTING,
      finishbook FOR TESTING,
      create_mock_data,
      setup,
      teardown.
ENDCLASS.


CLASS ltcl_Books IMPLEMENTATION.

  METHOD class_setup.
    lo_environment = cl_cds_test_environment=>create_for_multiple_cds(
        i_for_entities = VALUE #(
            ( i_for_entity = 'zrap_iv_books'
              "i_dependency_list = value #( ( '' ) )
              i_select_base_dependencies = abap_true
             )
        )
    ).
  ENDMETHOD.

  METHOD class_teardown.
    lo_environment->destroy(  ).
    "lo_environment_data_base->destroy(  ).
  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT lo_cut FOR TESTING.
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
    lo_environment->clear_doubles(  ).
    "lo_environment_data_base->clear_doubles(  ).
    CLEAR: lt_books_mock.
  ENDMETHOD.

  METHOD create_mock_data.
    lt_books_mock = VALUE #( ( Book_Guid = '1'
                               Author = 'Rene'
                               Book_Pages = 300
                               Genre = 'Tech' ) ).
    lo_environment->insert_test_data( lt_books_mock ).
  ENDMETHOD.

  METHOD finishbook.
    create_mock_data(  ).

    READ ENTITIES OF zrap_iv_books
        ENTITY Books
            ALL FIELDS
            WITH VALUE #( ( BookGuid = '1' ) )
        RESULT DATA(lt_books).

    lo_cut->finishbook(
        EXPORTING
            keys = value #( ( bookguid = lt_books[ 1 ]-bookguid ) )
    ).

    READ ENTITIES OF zrap_iv_books
        ENTITY Books
            ALL FIELDS
            WITH VALUE #( ( BookGuid = '1' ) )
        RESULT lt_books.

    cl_abap_unit_assert=>assert_equals(
        EXPORTING
            act = lt_books[ 1 ]-ReadingFinished
            exp = 'X'
            msg = 'Book should be marked as finished'
    ).
  ENDMETHOD.

  METHOD test_demo.
    create_mock_data( ).

    READ ENTITIES OF zrap_iv_books
        ENTITY Books
            ALL FIELDS
            WITH VALUE #( ( BookGuid = '1' ) )
        RESULT DATA(lt_books).

    cl_abap_unit_assert=>assert_not_initial(
        msg = 'Check if book can be found'
        act = lt_books
    ).

    READ ENTITIES OF zrap_iv_books
        ENTITY Books
            ALL FIELDS
            WITH VALUE #( ( BookGuid = '2' ) )
        RESULT lt_books.

    cl_abap_unit_assert=>assert_initial(
        msg = 'Check if book can be found'
        act = lt_books
    ).
  ENDMETHOD.

ENDCLASS.
