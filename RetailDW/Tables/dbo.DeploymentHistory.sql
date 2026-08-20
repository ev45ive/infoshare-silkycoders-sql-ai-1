-- Audit trail of database deployments. Every post-deployment run must append
-- exactly one row describing what was applied.
CREATE TABLE [dbo].[DeploymentHistory]
(
    [DeploymentId]  INT             IDENTITY (1, 1) NOT NULL,
    [ScriptName]    NVARCHAR (200)  NOT NULL,
    [AppliedAt]     DATETIME2 (3)   NOT NULL CONSTRAINT [DF_DeploymentHistory_AppliedAt] DEFAULT (SYSUTCDATETIME()),
    [AppliedBy]     NVARCHAR (128)  NOT NULL CONSTRAINT [DF_DeploymentHistory_AppliedBy] DEFAULT (SUSER_SNAME()),
    [Notes]         NVARCHAR (1000) NULL,
    CONSTRAINT [PK_DeploymentHistory] PRIMARY KEY CLUSTERED ([DeploymentId] ASC),
    CONSTRAINT [UQ_DeploymentHistory_ScriptName] UNIQUE NONCLUSTERED ([ScriptName] ASC)
);
