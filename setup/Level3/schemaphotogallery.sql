SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Table [dbo].[Comments] ******/
CREATE TABLE [dbo].[Comments](
	[CommentDate] [datetime] NOT NULL,
	[CommentText] [nvarchar](4000) NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PhotoId] [int] NULL,
	[UserId] [int] NULL,
 CONSTRAINT [Comments_PK__Comments__000000000000000C] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO


/****** Object:  Table [dbo].[Galleries] ******/
CREATE TABLE [dbo].[Galleries](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](4000) NOT NULL,
 CONSTRAINT [Galleries_PK__Galleries__0000000000000040] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO



/****** Object:  Table [dbo].[Photos] ******/
CREATE TABLE [dbo].[Photos](
	[ContentType] [nvarchar](4000) NULL,
	[Description] [nvarchar](4000) NULL,
	[FileExtension] [nvarchar](4000) NULL,
	[FileSize] [int] NOT NULL,
	[FileTitle] [nvarchar](4000) NOT NULL,
	[GalleryId] [int] NOT NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UploadDate] [datetime] NOT NULL,
	[UserId] [int] NULL,
	[primaryURI] [nvarchar](4000) NULL,
 CONSTRAINT [Photos_PK__Photos__0000000000000028] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO

/****** Object:  Table [dbo].[Photos_Tags] ******/
CREATE TABLE [dbo].[Photos_Tags](
	[Photos_Id] [int] NOT NULL,
	[Tags_TagName] [nvarchar](128) NOT NULL,
 CONSTRAINT [Photos_Tags_PK__Photos_Tags__000000000000004A] PRIMARY KEY CLUSTERED 
(
	[Photos_Id] ASC,
	[Tags_TagName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO

/****** Object:  Table [dbo].[Tags] ******/
CREATE TABLE [dbo].[Tags](
	[TagName] [nvarchar](128) NOT NULL,
 CONSTRAINT [Tags_PK__Tags__0000000000000052] PRIMARY KEY CLUSTERED 
(
	[TagName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO

/****** Object:  Table [dbo].[UserProfiles] ******/
CREATE TABLE [dbo].[UserProfiles](
	[Bio] [nvarchar](4000) NULL,
	[DisplayName] [nvarchar](4000) NULL,
	[Email] [nvarchar](4000) NULL,
	[UserId] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [UserProfiles_PK__UserProfiles__0000000000000036] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO

/****** Object:  Table [dbo].[webpages_Membership] ******/
CREATE TABLE [dbo].[webpages_Membership](
	[UserId] [int] NOT NULL,
	[CreateDate] [datetime] NULL,
	[ConfirmationToken] [nvarchar](128) NULL,
	[IsConfirmed] [bit] NULL,
	[LastPasswordFailureDate] [datetime] NULL,
	[PasswordFailuresSinceLastSuccess] [int] NOT NULL,
	[Password] [nvarchar](128) NOT NULL,
	[PasswordChangedDate] [datetime] NULL,
	[PasswordSalt] [nvarchar](128) NOT NULL,
	[PasswordVerificationToken] [nvarchar](128) NULL,
	[PasswordVerificationTokenExpirationDate] [datetime] NULL,
 CONSTRAINT [webpages_Membership_PK__webpages_Membership__000000000000009A] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO

/****** Object:  Table [dbo].[webpages_OAuthMembership] ******/
CREATE TABLE [dbo].[webpages_OAuthMembership](
	[Provider] [nvarchar](30) NOT NULL,
	[ProviderUserId] [nvarchar](100) NOT NULL,
	[UserId] [int] NOT NULL,
 CONSTRAINT [webpages_OAuthMembership_PK__webpages_OAuthMembership__0000000000000078] PRIMARY KEY CLUSTERED 
(
	[Provider] ASC,
	[ProviderUserId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO

/****** Object:  Table [dbo].[webpages_Roles]    Script Date: 10/16/2014 16:00:45 ******/

CREATE TABLE [dbo].[webpages_Roles](
	[RoleId] [int] IDENTITY(1,1) NOT NULL,
	[RoleName] [nvarchar](256) NOT NULL,
 CONSTRAINT [webpages_Roles_PK__webpages_Roles__00000000000000A4] PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON),
 CONSTRAINT [webpages_Roles_UQ__webpages_Roles__00000000000000A9] UNIQUE NONCLUSTERED 
(
	[RoleName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO

/****** Object:  Table [dbo].[webpages_UsersInRoles] ******/
CREATE TABLE [dbo].[webpages_UsersInRoles](
	[UserId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
 CONSTRAINT [webpages_UsersInRoles_PK__webpages_UsersInRoles__00000000000000B3] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
GO


/****** Constraints ******/
ALTER TABLE [dbo].[webpages_UsersInRoles]  WITH CHECK ADD  CONSTRAINT [webpages_UsersInRoles_fk_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[webpages_Roles] ([RoleId])
GO

ALTER TABLE [dbo].[webpages_UsersInRoles] CHECK CONSTRAINT [webpages_UsersInRoles_fk_RoleId]
GO

ALTER TABLE [dbo].[webpages_UsersInRoles]  WITH CHECK ADD  CONSTRAINT [webpages_UsersInRoles_fk_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[UserProfiles] ([UserId])
GO

ALTER TABLE [dbo].[webpages_UsersInRoles] CHECK CONSTRAINT [webpages_UsersInRoles_fk_UserId]
GO

ALTER TABLE [dbo].[Photos_Tags]  WITH CHECK ADD  CONSTRAINT [Photos_Tags_FK_Photos_Tags_Photos_Id_Photos_Id] FOREIGN KEY([Photos_Id])
REFERENCES [dbo].[Photos] ([Id])
GO

ALTER TABLE [dbo].[Photos_Tags] CHECK CONSTRAINT [Photos_Tags_FK_Photos_Tags_Photos_Id_Photos_Id]
GO

ALTER TABLE [dbo].[Photos_Tags]  WITH CHECK ADD  CONSTRAINT [Photos_Tags_FK_Photos_Tags_Tags_TagName_Tags_TagName] FOREIGN KEY([Tags_TagName])
REFERENCES [dbo].[Tags] ([TagName])
GO

ALTER TABLE [dbo].[Photos_Tags] CHECK CONSTRAINT [Photos_Tags_FK_Photos_Tags_Tags_TagName_Tags_TagName]
GO

ALTER TABLE [dbo].[Photos]  WITH CHECK ADD  CONSTRAINT [Photos_FK_Photos_GalleryId_Galleries_Id] FOREIGN KEY([GalleryId])
REFERENCES [dbo].[Galleries] ([Id])
GO

ALTER TABLE [dbo].[Photos] CHECK CONSTRAINT [Photos_FK_Photos_GalleryId_Galleries_Id]
GO

ALTER TABLE [dbo].[Photos]  WITH CHECK ADD  CONSTRAINT [Photos_FK_Photos_UserId_UserProfiles_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[UserProfiles] ([UserId])
GO

ALTER TABLE [dbo].[Photos] CHECK CONSTRAINT [Photos_FK_Photos_UserId_UserProfiles_UserId]
GO

ALTER TABLE [dbo].[Comments]  WITH CHECK ADD  CONSTRAINT [Comments_FK_Comments_PhotoId_Photos_Id] FOREIGN KEY([PhotoId])
REFERENCES [dbo].[Photos] ([Id])
GO

ALTER TABLE [dbo].[Comments] CHECK CONSTRAINT [Comments_FK_Comments_PhotoId_Photos_Id]
GO

ALTER TABLE [dbo].[Comments]  WITH CHECK ADD  CONSTRAINT [Comments_FK_Comments_UserId_UserProfiles_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[UserProfiles] ([UserId])
GO

ALTER TABLE [dbo].[Comments] CHECK CONSTRAINT [Comments_FK_Comments_UserId_UserProfiles_UserId]
GO

ALTER TABLE [dbo].[webpages_Membership] ADD  CONSTRAINT [DF_webpages_Membership_IsConfirmed]  DEFAULT ((0)) FOR [IsConfirmed]
GO

ALTER TABLE [dbo].[webpages_Membership] ADD  CONSTRAINT [DF_webpages_Membership_PasswordFailuresSinceLastSuccess]  DEFAULT ((0)) FOR [PasswordFailuresSinceLastSuccess]
GO