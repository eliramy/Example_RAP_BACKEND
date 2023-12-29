@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Entity - Books'

define root view entity ZRAP_IV_BOOKS as select from zrap_books {
    
    key book_guid as BookGuid,
    isbn as ISBN,
    title as Title,
    genre as Genre,
    author as Author,
    book_pages as BookPages,
    description as Description,
    purch_date as PurchasingDate,
    finished as ReadingFinished,
    rating as Rating,
    note as Note,
    @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        acceptableMimeTypes: ['image/png', 'image/png', 'application/pdf'],
        contentDispositionPreference: #ATTACHMENT
    }
    attachment as Attachment,
    @Semantics.mimeType: true
    mimetype as MimeType,
    filename as FileName,
    @Semantics.systemDateTime.lastChangedAt: true
    changed_at as ChangedAt,
    @Semantics.user.lastChangedBy: true
    changed_by as ChangedBy,
    @Semantics.systemDateTime.createdAt: true
    created_at as CreatedAt,
    @Semantics.user.createdBy: true
    created_by as CreatedBy,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    total_changed_at as TotalChangedAt
    
}
