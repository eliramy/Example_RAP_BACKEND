CLASS zcl_unit_test_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

PUBLIC SECTION.
PROTECTED SECTION.
PRIVATE SECTION.
    CLASS-DATA:
      cds_test_environment TYPE REF TO if_cds_test_environment,
*      sql_test_environment TYPE REF TO if_osql_test_environment,
      lt_books_mock TYPE STANDARD TABLE OF zrap_books.

    CLASS-METHODS:
      class_setup,    " setup test double framework
      class_teardown. " stop test doubles
     METHODS:
      setup,          " reset test doubles
      teardown.       " rollback any changes

     METHODS:
      demo_test FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS zcl_unit_test_demo IMPLEMENTATION.
  METHOD class_setup.
   " create the test doubles for the underlying CDS entities
   cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
        i_for_entities = VALUE #(
            ( i_for_entity = 'ZRAP_IV_BOOKS'
              i_select_base_dependencies = abap_true
             )
        )
    ).

   " create test doubles for additional used tables.
*   sql_test_environment = cl_osql_test_environment=>create(
*    i_dependency_list = VALUE #( ( 'zrap_books' ) )
*   ).

   " prepare the test data
   lt_books_mock = VALUE #( ( Book_Guid = 'C15A92C466201EEDB692C4A4EBB25A0C'
                              Author = 'Rene'
                              Book_Pages = 300
                              Genre = 'Tech' ) ).
  ENDMETHOD.

  METHOD class_teardown.
   " remove test doubles
   cds_test_environment->destroy(  ).
*   sql_test_environment->destroy(  ).
  ENDMETHOD.

  METHOD setup.
  " clear the test doubles per test
  cds_test_environment->clear_doubles(  ).
*  sql_test_environment->clear_doubles(  ).
  " insert test data into test doubles
  cds_test_environment->insert_test_data( lt_books_mock ).
*  sql_test_environment->insert_test_data( lt_books_mock ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD demo_test.
    MODIFY ENTITIES OF zrap_iv_books
        ENTITY Books
            EXECUTE finishBook
            FROM VALUE #( ( BookGuid = 'C15A92C466201EEDB692C4A4EBB25A0C'  ) )

        MAPPED DATA(mapped)
        FAILED DATA(failed)
        REPORTED DATA(reported).

   " expect no failures
   cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).

   " read the data from the persisted travel entity (using the test doubles)
   READ ENTITIES OF zrap_iv_books
    ENTITY Books
    ALL FIELDS WITH VALUE #( ( BookGuid = 'C15A92C466201EEDB692C4A4EBB25A0C' )  )
    RESULT DATA(lt_books).

   " expect the boolean "readingFinished" to be true for guid "C15A92C466201EEDB692C4A4EBB25A0C"
   cl_abap_unit_assert=>assert_equals(
    msg = 'Boolean changed'
    act = lt_books[ 1 ]-ReadingFinished
    exp = 'X'
   ).
  ENDMETHOD.

ENDCLASS.
