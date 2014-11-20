CREATE OR REPLACE VIEW APPS.XXSKZ_ファイルUpload_IF_基本_V
(
 FILE_NAME
,FILE_CONTENT_TYPE
,FILE_DATA
,FILE_FORMAT
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        XMFUI.file_name                     --FILE_NAME
       ,XMFUI.file_content_type             --FILE_CONTENT_TYPE
       ,XMFUI.file_data                     --FILE_DATA
       ,XMFUI.file_format                   --FILE_FORMAT
       ,FU_CB.user_name                     --作成者
       ,TO_CHAR( XMFUI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --作成日
       ,FU_LU.user_name                     --最終更新者
       ,TO_CHAR( XMFUI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --最終更新日
       ,FU_LL.user_name                     --最終更新ログイン
FROM    xxinv_mrp_file_ul_interface XMFUI
       ,fnd_user                    FU_CB   --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                    FU_LU   --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                    FU_LL   --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                  FL_LL   --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE  FU_CB.user_id(+)  = XMFUI.created_by
  AND  FU_LU.user_id(+)  = XMFUI.last_updated_by
  AND  FL_LL.login_id(+) = XMFUI.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_ファイルUpload_IF_基本_V                     IS 'SKILINK用ファイルUpload_IF(基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.FILE_NAME          IS 'FILE_NAME'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.FILE_CONTENT_TYPE  IS 'FILE_CONTENT_TYPE'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.FILE_DATA          IS 'FILE_DATA'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.FILE_FORMAT        IS 'FILE_FORMAT'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_ファイルUpload_IF_基本_V.最終更新ログイン   IS '最終更新ログイン'
/
