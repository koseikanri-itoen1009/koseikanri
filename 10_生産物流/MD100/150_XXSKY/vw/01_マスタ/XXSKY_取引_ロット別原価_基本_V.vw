CREATE OR REPLACE VIEW APPS.XXSKY_���_���b�g�ʌ���_��{_V
(
 �����^�C�v
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�����
,�������
,�P��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XTLC.doc_type               --�����^�C�v
       ,XPCV.prod_class_code        --���i�敪
       ,XPCV.prod_class_name        --���i�敪��
       ,XICV.item_class_code        --�i�ڋ敪
       ,XICV.item_class_name        --�i�ڋ敪��
       ,XCCV.crowd_code             --�Q�R�[�h
       ,XTLC.item_code              --�i�ڃR�[�h
       ,XIMV.item_name              --�i�ږ�
       ,XIMV.item_short_name        --�i�ڗ���
       ,XTLC.lot_num                --���b�gNo
       ,ILM.attribute1              --�����N����
       ,ILM.attribute2              --�ŗL�L��
       ,ILM.attribute3              --�ܖ�����
       ,XTLC.trans_qty              --�������
       ,XTLC.unit_price             --�P��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name             --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XTLC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XTLC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                    --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name             --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XTLC.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XTLC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                    --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name             --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XTLC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id          = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxcmn_txn_lot_cost  XTLC    --����ʃ��b�g�ʌ����A�h�I��
       ,xxsky_prod_class_v  XPCV    --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v  XICV    --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v  XCCV    --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxsky_item_mst_v    XIMV    --�i�ڍ��ڎ擾VIEW
       ,ic_lots_mst         ILM
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,fnd_user            FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       --,fnd_user            FU_LU   --���[�U�[�}�X�^(LAST_UPDATED_BY���̎擾�p)
       --,fnd_user            FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       --,fnd_logins          FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XTLC.item_id = XPCV.item_id(+)
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
   --AND  XTLC.item_id = XICV.item_id(+)
   --AND  XTLC.item_id = XCCV.item_id(+)
   AND  XPCV.item_id = XICV.item_id
   AND  XPCV.item_id = XCCV.item_id
   AND  XICV.item_id = XCCV.item_id
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
   AND  XTLC.item_id = XIMV.item_id(+)
   AND  XTLC.item_id = ILM.item_id(+)
   AND  XTLC.lot_id  = ILM.lot_id(+)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  XTLC.created_by        = FU_CB.user_id(+)
   --AND  XTLC.last_updated_by   = FU_LU.user_id(+)
   --AND  XTLC.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id          = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKY_���_���b�g�ʌ���_��{_V IS 'SKYLINK�p����ʃ��b�g�ʌ����i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�����^�C�v                       IS '�����^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.���i�敪                         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.���i�敪��                       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�i�ڋ敪                         IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�i�ڋ敪��                       IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�Q�R�[�h                         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�i�ڃR�[�h                       IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�i�ږ�                           IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�i�ڗ���                         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.���b�gNO                         IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�����N����                       IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�ŗL�L��                         IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�ܖ�����                         IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�������                         IS '�������'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�P��                             IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�쐬��                           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�쐬��                           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�ŏI�X�V��                       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�ŏI�X�V��                       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���_���b�g�ʌ���_��{_V.�ŏI�X�V���O�C��                 IS '�ŏI�X�V���O�C��'
/

