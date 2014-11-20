CREATE OR REPLACE VIEW APPS.XXSKY_�^���Ǝ҃}�X�^_����_V
(
 �^���Ǝ҃R�[�h
,�^���ƎҖ�
,�^���Ǝҗ���
,�^���Ǝ҃J�i��
,�K�p�J�n��
,�K�p�I����
,�X�֔ԍ�
,�Z���P
,�Z���Q
,�d�b�ԍ�
,FAX�ԍ�
,EOS����
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  WC.freight_code            --�^���Ǝ҃R�[�h
       ,XP.party_name              --�^���ƎҖ�
       ,XP.party_short_name        --�^���Ǝҗ���
       ,XP.party_name_alt          --�^���Ǝ҃J�i��
       ,XP.start_date_active       --�K�p�J�n��
       ,XP.end_date_active         --�K�p�I����
       ,XP.zip                     --�X�֔ԍ�
       ,XP.address_line1           --�Z���P
       ,XP.address_line2           --�Z���Q
       ,XP.phone                   --�d�b�ԍ�
       ,XP.fax                     --FAX�ԍ�
       ,XP.eos_detination          --EOS����
       ,FU_CB.user_name            --�쐬��
       ,TO_CHAR( XP.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                   --�쐬��
       ,FU_LU.user_name            --�ŏI�X�V��
       ,TO_CHAR( XP.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                   --�ŏI�X�V��
       ,FU_LL.user_name            --�ŏI�X�V���O�C��
  FROM  xxcmn_parties   XP         --�p�[�e�B�A�h�I���}�X�^
       ,wsh_carriers    WC
       ,hz_parties      HP         --�p�[�e�B�}�X�^
       ,fnd_user        FU_CB      --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user        FU_LU      --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user        FU_LL      --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins      FL_LL      --���O�C���}�X�^(last_update_login���̎擾�p)
 WHERE  XP.party_id = WC.carrier_id
   AND  XP.party_id = HP.party_id
   AND  XP.created_by        = FU_CB.user_id(+)
   AND  XP.last_updated_by   = FU_LU.user_id(+)
   AND  XP.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id        = FU_LL.user_id(+)
   AND  HP.status            = 'A'  --�X�e�[�^�X�F�L��
   AND  XP.start_date_active <= TRUNC(SYSDATE)
   AND  XP.end_date_active   >= TRUNC(SYSDATE)
/

COMMENT ON TABLE APPS.XXSKY_�^���Ǝ҃}�X�^_����_V IS 'SKYLINK�p�^���Ǝ҃}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�^���Ǝ҃R�[�h                 IS '�^���Ǝ҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�^���ƎҖ�                     IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�^���Ǝҗ���                   IS '�^���Ǝҗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�^���Ǝ҃J�i��                 IS '�^���Ǝ҃J�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�K�p�J�n��                     IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�K�p�I����                     IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�X�֔ԍ�                       IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�Z���P                         IS '�Z���P'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�Z���Q                         IS '�Z���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�d�b�ԍ�                       IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.FAX�ԍ�                        IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.EOS����                        IS 'EOS����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���Ǝ҃}�X�^_����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
