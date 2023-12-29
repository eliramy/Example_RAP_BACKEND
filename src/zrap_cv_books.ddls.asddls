@EndUserText.label: 'CDS Projection - Books'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true

@Search.searchable: true

define root view entity ZRAP_CV_BOOKS as projection on ZRAP_IV_BOOKS {
    key BookGuid,
    @Search.defaultSearchElement: true
    ISBN,
    @Search.defaultSearchElement: true
    Title,
    Genre,
    Author,
    BookPages,
    Description,
    PurchasingDate,
    ReadingFinished,
    Rating,
    Note,
    Attachment,
    MimeType,
    FileName,
    ChangedAt,
    ChangedBy,
    CreatedAt,
    CreatedBy,
    TotalChangedAt
}
