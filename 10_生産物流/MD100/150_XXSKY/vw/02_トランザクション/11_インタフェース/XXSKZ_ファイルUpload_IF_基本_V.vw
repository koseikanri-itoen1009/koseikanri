CREATE OR REPLACE VIEW APPS.XXSKZ_�t�@�C��Upload_IF_��{_V
(
 FILE_NAME
,FILE_CONTENT_TYPE
,FILE_DATA
,FILE_FORMAT
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XMFUI.file_name                     --FILE_NAME
       ,XMFUI.file_content_type             --FILE_CONTENT_TYPE
       ,XMFUI.file_data                     --FILE_DATA
       ,XMFUI.file_format                   --FILE_FORMAT
       ,FU_CB.user_name                     --�쐬��
       ,TO_CHAR( XMFUI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,TO_CHAR( XMFUI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
FROM    xxinv_mrp_file_ul_interface XMFUI
       ,fnd_user                    FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                    FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                    FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                  FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE  FU_CB.user_id(+)  = XMFUI.created_by
  AND  FU_LU.user_id(+)  = XMFUI.last_updated_by
  AND  FL_LL.login_id(+) = XMFUI.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�t�@�C��Upload_IF_��{_V                     IS 'SKILINK�p�t�@�C��Upload_IF(��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.FILE_NAME          IS 'FILE_NAME'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.FILE_CONTENT_TYPE  IS 'FILE_CONTENT_TYPE'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.FILE_DATA          IS 'FILE_DATA'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.FILE_FORMAT        IS 'FILE_FORMAT'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�t�@�C��Upload_IF_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/
