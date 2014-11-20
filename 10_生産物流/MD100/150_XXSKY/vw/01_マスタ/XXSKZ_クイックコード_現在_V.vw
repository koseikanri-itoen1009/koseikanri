/*************************************************************************
 * 
 * View  Name      : XXSKZ_�N�C�b�N�R�[�h_����_V
 * Description     : XXSKZ_�N�C�b�N�R�[�h_����_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�N�C�b�N�R�[�h_����_V
(
 �Q�ƃ^�C�v
,�Q�ƃ^�C�v��
,�Q�ƃ^�C�v�E�v
,�A�v���P�[�V������
,�Q�ƃR�[�h
,�Q�ƃR�[�h_���e
,�Q�ƃR�[�h_�E�v
,�R���e�L�X�g
,�����P
,�����Q
,�����R
,�����S
,�����T
,�����U
,�����V
,�����W
,�����X
,�����P�O
,�����P�P
,�����P�Q
,�����P�R
,�����P�S
,�����P�T
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        FLV.lookup_type                  --�Q�ƃ^�C�v
       ,FLTT.meaning                     --�Q�ƃ^�C�v��
       ,FLTT.description                 --�Q�ƃ^�C�v�E�v
       ,FAT.application_name             --�A�v���P�[�V������
       ,FLV.lookup_code                  --�Q�ƃR�[�h
       ,FLV.meaning                      --�Q�ƃR�[�h_���e
       ,FLV.description                  --�Q�ƃR�[�h_�E�v
       ,FLV.attribute_category           --�R���e�L�X�g
       ,FLV.attribute1                   --�����P
       ,FLV.attribute2                   --�����Q
       ,FLV.attribute3                   --�����R
       ,FLV.attribute4                   --�����S
       ,FLV.attribute5                   --�����T
       ,FLV.attribute6                   --�����U
       ,FLV.attribute7                   --�����V
       ,FLV.attribute8                   --�����W
       ,FLV.attribute9                   --�����X
       ,FLV.attribute10                  --�����P�O
       ,FLV.attribute11                  --�����P�P
       ,FLV.attribute12                  --�����P�Q
       ,FLV.attribute13                  --�����P�R
       ,FLV.attribute14                  --�����P�S
       ,FLV.attribute15                  --�����P�T
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                  --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB     --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE FLV.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( FLV.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                  --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU     --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE FLV.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( FLV.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                  --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL     --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL     --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE FLV.last_update_login = FL_LL.login_id
         AND  FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  fnd_application        FA        --
       ,fnd_lookup_types       FLT       --
       ,fnd_lookup_values      FLV       --�N�C�b�N�R�[�h�l
       ,fnd_lookup_types_tl    FLTT      --
       ,fnd_application_tl     FAT       --
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,fnd_user               FU_CB     --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user               FU_LU     --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user               FU_LL     --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins             FL_LL     --���O�C���}�X�^(last_update_login���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  SUBSTRB(FA.application_short_name, 1, 2) = 'XX'
   AND  FA.application_id = FLT.application_id
   AND  FLT.lookup_type = FLV.lookup_type(+)
   AND  FLV.start_date_active <= TRUNC(SYSDATE)
   AND  (FLV.end_date_active   >= TRUNC(SYSDATE)
         OR FLV.end_date_active IS NULL)
   AND  FLV.language(+) = 'JA'
   AND  FLT.lookup_type = FLTT.lookup_type(+)
   AND  FLT.view_application_id = FLTT.view_application_id(+)
   AND  FLT.security_group_id = FLTT.security_group_id(+)
   AND  FLTT.language(+) = 'JA'
   AND  FLT.application_id = FAT.application_id(+)
   AND  FAT.language = 'JA'
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  FLV.created_by        = FU_CB.user_id(+)
   --AND  FLV.last_updated_by   = FU_LU.user_id(+)
   --AND  FLV.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKZ_�N�C�b�N�R�[�h_����_V IS 'SKYLINK�p�N�C�b�N�R�[�h�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�Q�ƃ^�C�v         IS '�Q�ƃ^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�Q�ƃ^�C�v��       IS '�Q�ƃ^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�Q�ƃ^�C�v�E�v     IS '�Q�ƃ^�C�v�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�A�v���P�[�V������ IS '�A�v���P�[�V������'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�Q�ƃR�[�h         IS '�Q�ƃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�Q�ƃR�[�h_���e    IS '�Q�ƃR�[�h_���e'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�Q�ƃR�[�h_�E�v    IS '�Q�ƃR�[�h_�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�R���e�L�X�g       IS '�R���e�L�X�g'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����P             IS '�����P'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����Q             IS '�����Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����R             IS '�����R'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����S             IS '�����S'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����T             IS '�����T'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����U             IS '�����U'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����V             IS '�����V'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����W             IS '�����W'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����X             IS '�����X'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����P�O           IS '�����P�O'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����P�P           IS '�����P�P'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����P�Q           IS '�����P�Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����P�R           IS '�����P�R'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����P�S           IS '�����P�S'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�����P�T           IS '�����P�T'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�N�C�b�N�R�[�h_����_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/