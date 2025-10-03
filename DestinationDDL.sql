-- DROP SCHEMA music;

CREATE SCHEMA music;
-- MusicCollection.music.ArtistType definition

-- Drop table

-- DROP TABLE MusicCollection.music.ArtistType;

CREATE TABLE MusicCollection.music.ArtistType (
	ArtistTypeId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Description nvarchar(400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__ArtistTy__8554BEEBC969CCFF PRIMARY KEY (ArtistTypeId),
	CONSTRAINT UQ__ArtistTy__737584F61C79A7C3 UNIQUE (Name)
);


-- MusicCollection.music.Country definition

-- Drop table

-- DROP TABLE MusicCollection.music.Country;

CREATE TABLE MusicCollection.music.Country (
	CountryId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CountryCode char(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Description nvarchar(400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__Country__10D1609F07A9A53D PRIMARY KEY (CountryId),
	CONSTRAINT UQ__Country__737584F658EA7F1E UNIQUE (Name)
);


-- MusicCollection.music.MediaAsset definition

-- Drop table

-- DROP TABLE MusicCollection.music.MediaAsset;

CREATE TABLE MusicCollection.music.MediaAsset (
	MediaAssetId int IDENTITY(1,1) NOT NULL,
	OwnerType tinyint NOT NULL,
	OwnerId int NOT NULL,
	Kind nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Uri nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MimeType nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Width int NULL,
	Height int NULL,
	SortOrder int NULL,
	CreatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	CONSTRAINT PK__MediaAss__0F3E13BE6AC542AB PRIMARY KEY (MediaAssetId),
	CONSTRAINT UX_MediaAsset UNIQUE (OwnerType,OwnerId,Kind,SortOrder)
);
 CREATE NONCLUSTERED INDEX IX_MediaAsset_Owner ON MusicCollection.music.MediaAsset (  OwnerType ASC  , OwnerId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.MediumFormat definition

-- Drop table

-- DROP TABLE MusicCollection.music.MediumFormat;

CREATE TABLE MusicCollection.music.MediumFormat (
	MediumFormatId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Kind int NOT NULL,
	Description nvarchar(400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__MediumFo__21B4EBDCDFB369AB PRIMARY KEY (MediumFormatId),
	CONSTRAINT UQ__MediumFo__737584F6E28CC52D UNIQUE (Name)
);


-- MusicCollection.music.Tag definition

-- Drop table

-- DROP TABLE MusicCollection.music.Tag;

CREATE TABLE MusicCollection.music.Tag (
	TagId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CONSTRAINT PK__Tag__657CF9AC5198A3C1 PRIMARY KEY (TagId),
	CONSTRAINT UQ__Tag__737584F615D832A2 UNIQUE (Name)
);
 CREATE NONCLUSTERED INDEX IX_Tag_Name ON MusicCollection.music.Tag (  Name ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.Website definition

-- Drop table

-- DROP TABLE MusicCollection.music.Website;

CREATE TABLE MusicCollection.music.Website (
	WebsiteId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Url nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CONSTRAINT PK__Website__3F146DA99AF5A40D PRIMARY KEY (WebsiteId),
	CONSTRAINT UQ__Website__737584F676E6E6C3 UNIQUE (Name)
);


-- MusicCollection.music.Artist definition

-- Drop table

-- DROP TABLE MusicCollection.music.Artist;

CREATE TABLE MusicCollection.music.Artist (
	ArtistId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SortName nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ArtistTypeId int NULL,
	IsGroup bit DEFAULT 0 NOT NULL,
	Description nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CountryId int NULL,
	FirstActivityYear int NULL,
	CreatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	UpdatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	RowVersion timestamp NOT NULL,
	CONSTRAINT PK__Artist__25706B50331CF9F4 PRIMARY KEY (ArtistId),
	CONSTRAINT FK_Artist_Country FOREIGN KEY (CountryId) REFERENCES MusicCollection.music.Country(CountryId),
	CONSTRAINT FK_Artist_Type FOREIGN KEY (ArtistTypeId) REFERENCES MusicCollection.music.ArtistType(ArtistTypeId)
);
 CREATE NONCLUSTERED INDEX IX_Artist_ArtistTypeId ON MusicCollection.music.Artist (  ArtistTypeId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Artist_CountryId ON MusicCollection.music.Artist (  CountryId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Artist_Name ON MusicCollection.music.Artist (  Name ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Artist_SortName ON MusicCollection.music.Artist (  SortName ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE UNIQUE NONCLUSTERED INDEX UX_Artist_Name_Country_Group ON MusicCollection.music.Artist (  Name ASC  , CountryId ASC  , IsGroup ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.ArtistMembership definition

-- Drop table

-- DROP TABLE MusicCollection.music.ArtistMembership;

CREATE TABLE MusicCollection.music.ArtistMembership (
	ArtistMembershipId int IDENTITY(1,1) NOT NULL,
	GroupArtistId int NOT NULL,
	MemberArtistId int NOT NULL,
	[Role] nvarchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	JoinedDate date NULL,
	LeftDate date NULL,
	[Sequence] int NULL,
	IsSession bit DEFAULT 0 NOT NULL,
	CONSTRAINT PK__ArtistMe__CE605B84430D1ED0 PRIMARY KEY (ArtistMembershipId),
	CONSTRAINT UX_Member UNIQUE (GroupArtistId,MemberArtistId,JoinedDate),
	CONSTRAINT FK_Member_Artist FOREIGN KEY (MemberArtistId) REFERENCES MusicCollection.music.Artist(ArtistId),
	CONSTRAINT FK_Member_Group FOREIGN KEY (GroupArtistId) REFERENCES MusicCollection.music.Artist(ArtistId)
);
 CREATE NONCLUSTERED INDEX IX_ArtistMembership_Group ON MusicCollection.music.ArtistMembership (  GroupArtistId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.Credit definition

-- Drop table

-- DROP TABLE MusicCollection.music.Credit;

CREATE TABLE MusicCollection.music.Credit (
	CreditId int IDENTITY(1,1) NOT NULL,
	TargetType tinyint NOT NULL,
	TargetId int NOT NULL,
	ArtistId int NOT NULL,
	[Role] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Instrument nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	IsPrimary bit DEFAULT 0 NOT NULL,
	[Sequence] int NULL,
	CONSTRAINT PK__Credit__ED5ED0BB7A0092AA PRIMARY KEY (CreditId),
	CONSTRAINT FK_Credit_Artist FOREIGN KEY (ArtistId) REFERENCES MusicCollection.music.Artist(ArtistId)
);
 CREATE NONCLUSTERED INDEX IX_Credit_Role ON MusicCollection.music.Credit (  Role ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Credit_Target ON MusicCollection.music.Credit (  TargetType ASC  , TargetId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.Genre definition

-- Drop table

-- DROP TABLE MusicCollection.music.Genre;

CREATE TABLE MusicCollection.music.Genre (
	GenreId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Description nvarchar(400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ParentGenreId int NULL,
	CONSTRAINT PK__Genre__0385057E7AAEC8A6 PRIMARY KEY (GenreId),
	CONSTRAINT UQ__Genre__737584F63D153A26 UNIQUE (Name),
	CONSTRAINT FK_Genre_Parent FOREIGN KEY (ParentGenreId) REFERENCES MusicCollection.music.Genre(GenreId)
);


-- MusicCollection.music.Identifier definition

-- Drop table

-- DROP TABLE MusicCollection.music.Identifier;

CREATE TABLE MusicCollection.music.Identifier (
	IdentifierId int IDENTITY(1,1) NOT NULL,
	EntityType tinyint NOT NULL,
	EntityId int NOT NULL,
	[Source] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Value nvarchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsPrimary bit DEFAULT 0 NOT NULL,
	WebsiteId int NULL,
	CONSTRAINT PK__Identifi__5EB5E6768E40A19E PRIMARY KEY (IdentifierId),
	CONSTRAINT UX_Identifier UNIQUE (EntityType,[Source],Value),
	CONSTRAINT FK_Identifier_Website FOREIGN KEY (WebsiteId) REFERENCES MusicCollection.music.Website(WebsiteId)
);
 CREATE NONCLUSTERED INDEX IX_Identifier_Entity ON MusicCollection.music.Identifier (  EntityType ASC  , EntityId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Identifier_EntityType_EntityId ON MusicCollection.music.Identifier (  EntityType ASC  , EntityId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Identifier_Value ON MusicCollection.music.Identifier (  Value ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Identifier_Website ON MusicCollection.music.Identifier (  WebsiteId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.Label definition

-- Drop table

-- DROP TABLE MusicCollection.music.Label;

CREATE TABLE MusicCollection.music.Label (
	LabelId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SortName nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CountryId int NULL,
	CONSTRAINT PK__Label__397E2BC31A69D90D PRIMARY KEY (LabelId),
	CONSTRAINT FK_Label_Country FOREIGN KEY (CountryId) REFERENCES MusicCollection.music.Country(CountryId)
);
 CREATE UNIQUE NONCLUSTERED INDEX UX_Label_Name_Country ON MusicCollection.music.Label (  Name ASC  , CountryId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.Recording definition

-- Drop table

-- DROP TABLE MusicCollection.music.Recording;

CREATE TABLE MusicCollection.music.Recording (
	RecordingId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	DurationMs int NULL,
	ISRC char(12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PrimaryArtistId int NULL,
	CreatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	CONSTRAINT PK__Recordin__5CA5A94C28AE83EE PRIMARY KEY (RecordingId),
	CONSTRAINT UX_Recording_ISRC UNIQUE (ISRC),
	CONSTRAINT FK_Recording_PrimaryArtist FOREIGN KEY (PrimaryArtistId) REFERENCES MusicCollection.music.Artist(ArtistId)
);


-- MusicCollection.music.Album definition

-- Drop table

-- DROP TABLE MusicCollection.music.Album;

CREATE TABLE MusicCollection.music.Album (
	AlbumId int IDENTITY(1,1) NOT NULL,
	Name nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SortName nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	PrimaryArtistId int NOT NULL,
	AlbumType int NOT NULL,
	FirstReleaseDate date NULL,
	Rating tinyint NULL,
	CreatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	UpdatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	RowVersion timestamp NOT NULL,
	CONSTRAINT PK__Album__97B4BE37200ECA36 PRIMARY KEY (AlbumId),
	CONSTRAINT FK_Album_PrimaryArtist FOREIGN KEY (PrimaryArtistId) REFERENCES MusicCollection.music.Artist(ArtistId)
);
 CREATE NONCLUSTERED INDEX IX_Album_Name ON MusicCollection.music.Album (  Name ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Album_PrimaryArtist_Date ON MusicCollection.music.Album (  PrimaryArtistId ASC  , FirstReleaseDate ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Album_SortName ON MusicCollection.music.Album (  SortName ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE MusicCollection.music.Album WITH NOCHECK ADD CONSTRAINT CK_Album_Date CHECK (([FirstReleaseDate] IS NULL OR [FirstReleaseDate]>='1900-01-01'));


-- MusicCollection.music.AlbumGenre definition

-- Drop table

-- DROP TABLE MusicCollection.music.AlbumGenre;

CREATE TABLE MusicCollection.music.AlbumGenre (
	AlbumId int NOT NULL,
	GenreId int NOT NULL,
	CONSTRAINT PK__AlbumGen__678CEE6048EC5410 PRIMARY KEY (AlbumId,GenreId),
	CONSTRAINT FK__AlbumGenr__Album__72E607DB FOREIGN KEY (AlbumId) REFERENCES MusicCollection.music.Album(AlbumId),
	CONSTRAINT FK__AlbumGenr__Genre__73DA2C14 FOREIGN KEY (GenreId) REFERENCES MusicCollection.music.Genre(GenreId)
);
 CREATE NONCLUSTERED INDEX IX_AlbumGenre_Genre ON MusicCollection.music.AlbumGenre (  GenreId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.ArtistGenre definition

-- Drop table

-- DROP TABLE MusicCollection.music.ArtistGenre;

CREATE TABLE MusicCollection.music.ArtistGenre (
	ArtistId int NOT NULL,
	GenreId int NOT NULL,
	CONSTRAINT PK__ArtistGe__D5483B0748FA29DE PRIMARY KEY (ArtistId,GenreId),
	CONSTRAINT FK__ArtistGen__Artis__6F1576F7 FOREIGN KEY (ArtistId) REFERENCES MusicCollection.music.Artist(ArtistId),
	CONSTRAINT FK__ArtistGen__Genre__70099B30 FOREIGN KEY (GenreId) REFERENCES MusicCollection.music.Genre(GenreId)
);
 CREATE NONCLUSTERED INDEX IX_ArtistGenre_Artist ON MusicCollection.music.ArtistGenre (  ArtistId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_ArtistGenre_Genre ON MusicCollection.music.ArtistGenre (  GenreId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.Edition definition

-- Drop table

-- DROP TABLE MusicCollection.music.Edition;

CREATE TABLE MusicCollection.music.Edition (
	EditionId int IDENTITY(1,1) NOT NULL,
	AlbumId int NOT NULL,
	Title nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Status int NOT NULL,
	ReleaseDate date NULL,
	Barcode bigint NULL,
	Packaging int NULL,
	Description nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	UpdatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	RowVersion timestamp NOT NULL,
	CONSTRAINT PK__Edition__C76223634428849D PRIMARY KEY (EditionId),
	CONSTRAINT FK_Edition_Album FOREIGN KEY (AlbumId) REFERENCES MusicCollection.music.Album(AlbumId)
);
 CREATE NONCLUSTERED INDEX IX_Edition_Album ON MusicCollection.music.Edition (  AlbumId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.EditionLabel definition

-- Drop table

-- DROP TABLE MusicCollection.music.EditionLabel;

CREATE TABLE MusicCollection.music.EditionLabel (
	EditionLabelId int IDENTITY(1,1) NOT NULL,
	EditionId int NOT NULL,
	LabelId int NOT NULL,
	CatalogNumber nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__EditionL__22EC88894682BB01 PRIMARY KEY (EditionLabelId),
	CONSTRAINT UX_EditionLabel UNIQUE (EditionId,LabelId,CatalogNumber),
	CONSTRAINT FK_EditionLabel_Edition FOREIGN KEY (EditionId) REFERENCES MusicCollection.music.Edition(EditionId),
	CONSTRAINT FK_EditionLabel_Label FOREIGN KEY (LabelId) REFERENCES MusicCollection.music.Label(LabelId)
);


-- MusicCollection.music.Disc definition

-- Drop table

-- DROP TABLE MusicCollection.music.Disc;

CREATE TABLE MusicCollection.music.Disc (
	DiscId int IDENTITY(1,1) NOT NULL,
	EditionId int NOT NULL,
	DiscNumber int NOT NULL,
	MediumFormatId int NULL,
	Name nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__Disc__14C198D0A0BB009C PRIMARY KEY (DiscId),
	CONSTRAINT UX_Disc UNIQUE (EditionId,DiscNumber),
	CONSTRAINT FK_Disc_Edition FOREIGN KEY (EditionId) REFERENCES MusicCollection.music.Edition(EditionId),
	CONSTRAINT FK_Disc_Format FOREIGN KEY (MediumFormatId) REFERENCES MusicCollection.music.MediumFormat(MediumFormatId)
);
 CREATE NONCLUSTERED INDEX IX_Disc_Edition ON MusicCollection.music.Disc (  EditionId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- MusicCollection.music.Track definition

-- Drop table

-- DROP TABLE MusicCollection.music.Track;

CREATE TABLE MusicCollection.music.Track (
	TrackId int IDENTITY(1,1) NOT NULL,
	DiscId int NOT NULL,
	RecordingId int NULL,
	Title nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SortTitle nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	TrackNumber int NOT NULL,
	[Position] int NOT NULL,
	DurationMs int NULL,
	ISRC char(12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	BPM decimal(6,2) NULL,
	MusicalKey nvarchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	LanguageCode char(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ExplicitFlag bit DEFAULT 0 NOT NULL,
	LyricsAvailable bit DEFAULT 0 NOT NULL,
	CreatedUtc datetime2 DEFAULT sysutcdatetime() NOT NULL,
	CONSTRAINT PK__Track__7A74F8E0CE492B9F PRIMARY KEY (TrackId),
	CONSTRAINT UX_Track_DiscNumber UNIQUE (DiscId,TrackNumber),
	CONSTRAINT UX_Track_DiscPosition UNIQUE (DiscId,[Position]),
	CONSTRAINT UX_Track_ISRC UNIQUE (ISRC),
	CONSTRAINT FK_Track_Disc FOREIGN KEY (DiscId) REFERENCES MusicCollection.music.Disc(DiscId),
	CONSTRAINT FK_Track_Recording FOREIGN KEY (RecordingId) REFERENCES MusicCollection.music.Recording(RecordingId)
);
 CREATE NONCLUSTERED INDEX IX_Track_Disc ON MusicCollection.music.Track (  DiscId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Track_Recording ON MusicCollection.music.Track (  RecordingId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Track_SortTitle ON MusicCollection.music.Track (  SortTitle ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IX_Track_Title ON MusicCollection.music.Track (  Title ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE MusicCollection.music.Track WITH NOCHECK ADD CONSTRAINT CK_Track_Duration CHECK (([DurationMs] IS NULL OR [DurationMs]>=(0)));


-- MusicCollection.music.TrackGenre definition

-- Drop table

-- DROP TABLE MusicCollection.music.TrackGenre;

CREATE TABLE MusicCollection.music.TrackGenre (
	TrackId int NOT NULL,
	GenreId int NOT NULL,
	CONSTRAINT PK__TrackGen__8A4CA8B7AB91C65B PRIMARY KEY (TrackId,GenreId),
	CONSTRAINT FK__TrackGenr__Genre__77AABCF8 FOREIGN KEY (GenreId) REFERENCES MusicCollection.music.Genre(GenreId),
	CONSTRAINT FK__TrackGenr__Track__76B698BF FOREIGN KEY (TrackId) REFERENCES MusicCollection.music.Track(TrackId)
);
 CREATE NONCLUSTERED INDEX IX_TrackGenre_Genre ON MusicCollection.music.TrackGenre (  GenreId ASC  )
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;