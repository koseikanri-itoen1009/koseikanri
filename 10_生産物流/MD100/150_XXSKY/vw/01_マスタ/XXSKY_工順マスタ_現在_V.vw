CREATE OR REPLACE VIEW APPS.XXSKY_�H���}�X�^_����_V
(
 �H���ԍ�
,�H����
,�H������
,�L��_��
,�L��_��
,�敪
,�敪��
,���C���敪
,���C���敪��
,�X�e�[�^�X
,�X�e�[�^�X��
,�v�摹��
,����
,�P��
,�����
,����於
,����
,�W���\��
,MIN�\��
,MAX�\��
,�[�i�ꏊ
,�[�i�ꏊ��
,�H��敪
,�H��敪��
,�H������C���z����
,���[�h�^�C��
,�`�[�敪
,�`�[�敪��
,���ъǗ�����
,���ъǗ�������
,���O�敪
,���O�敪��
,�����i�敪
,�����i�敪��
,�V�ʐ��敪
,�V�ʐ��敪��
,HHT���M�Ώۃt���O
,HHT���M�Ώۃt���O��
,�ŗL�L��
,�ŗL�L����
,��ƕ���
,��ƕ�����
,�[�i�q��
,�[�i�q�ɖ�
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  GRB.routing_no                 --�H���ԍ�
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,GRT.routing_desc               --�H����
       ,(SELECT GRT.routing_desc
         FROM gmd_routings_tl GRT     --�H���}�X�^(����)
         WHERE GRB.routing_id = GRT.routing_id
           AND  GRT.language  = 'JA'
        ) GRT_routing_desc      --�X�e�[�^�X��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute1                 --�H������
       ,GRB.effective_start_date       --�L��_��
       ,GRB.effective_end_date         --�L��_��
       ,GRB.routing_class              --�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,GRCT.routing_class_desc        --�敪��
       ,(SELECT GRCT.routing_class_desc
         FROM gmd_routing_class_tl GRCT   --�H���敪�}�X�^���{��
         WHERE GRB.routing_class = GRCT.routing_class
           AND GRCT.language     = 'JA'
        ) GRCT_routing_class_desc      --�X�e�[�^�X��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute2                 --���C���敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --�N�C�b�N�R�[�h(���C���敪��)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXCMN_PRODUCTION_LINE'
           AND FLV01.lookup_code = GRB.attribute2
        ) line_class_name                --���C���敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.routing_status             --�X�e�[�^�X
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,GQST.meaning
       ,(SELECT GQST.meaning
         FROM gmd_qc_status_tl GQST   --
         WHERE GQST.status_code = GRB.routing_status
           AND GQST.language    = 'JA'
           AND GQST.entity_type = 'S'
        ) status_name                    --�X�e�[�^�X��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.process_loss               --�v�摹��
       ,GRB.routing_qty                --����
       ,GRB.item_um                    --�P��
       ,GRB.attribute3                 --�����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,IWM01.whse_name                --����於
       ,(SELECT IWM01.whse_name
         FROM ic_whse_mst IWM01  --�q��(����於)
         WHERE IWM01.whse_code = GRB.attribute3
        ) IWM01_whse_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,NVL( TO_NUMBER( GRB.attribute5 ), 0 )
                                       --����
       ,NVL( TO_NUMBER( GRB.attribute6 ), 0 )
                                       --�W���\��
       ,NVL( TO_NUMBER( GRB.attribute7 ), 0 )
                                       --MIN�\��
       ,NVL( TO_NUMBER( GRB.attribute8 ), 0 )
                                       --MAX�\��
       ,GRB.attribute9                 --�[�i�ꏊ
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,MIL.description                --�[�i�ꏊ��
       ,(SELECT MIL.description
         FROM mtl_item_locations MIL    --OPM�ۊǏꏊ�}�X�^
         WHERE MIL.segment1 = GRB.attribute9
        ) MIL_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute10                --�H��敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --�N�C�b�N�R�[�h(�H��敪��)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXCMN_K04'
           AND FLV02.lookup_code = GRB.attribute10
        ) routing_class_name             --�H��敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,NVL( TO_NUMBER( GRB.attribute11 ), 0 )
                                       --�H������C���z����
       ,NVL( TO_NUMBER( GRB.attribute12 ), 0 )
                                       --���[�h�^�C��
       ,GRB.attribute13                --�`�[�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --�N�C�b�N�R�[�h(�`�[�敪��)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXCMN_L03'
           AND FLV03.lookup_code = GRB.attribute13
        ) den_class_name                 --�`�[�敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute14                --���ъǗ�����
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV04.meaning
       ,(SELECT FLV04.meaning
         FROM fnd_lookup_values FLV04  --�N�C�b�N�R�[�h(���ъǗ�������)
         WHERE FLV04.language    = 'JA'
           AND FLV04.lookup_type = 'XXCMN_L10'
           AND FLV04.lookup_code = GRB.attribute14
        ) seise_class_name               --���ъǗ�������
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute15                --���O�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV05.meaning
       ,(SELECT FLV05.meaning
         FROM fnd_lookup_values FLV05  --�N�C�b�N�R�[�h(���O�敪��)
         WHERE FLV05.language    = 'JA'
           AND FLV05.lookup_type = 'XXWIP_IN_OUT_TYPE'
           AND FLV05.lookup_code = GRB.attribute15
        ) inout_class_name               --���O�敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute16                --�����i�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV06.meaning
       ,(SELECT FLV06.meaning
         FROM fnd_lookup_values FLV06  --�N�C�b�N�R�[�h(�����i�敪��)
         WHERE FLV06.language    = 'JA'
           AND FLV06.lookup_type = 'XXWIP_PROD_TYPE'
           AND FLV06.lookup_code = GRB.attribute16
        ) seizo_class_name               --�����i�敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute17                --�V�ʐ��敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV07.meaning
       ,(SELECT FLV07.meaning
         FROM fnd_lookup_values FLV07  --�N�C�b�N�R�[�h(�V�ʐ��敪��)
         WHERE FLV07.language    = 'JA'
           AND FLV07.lookup_type = 'XXWIP_NEW_LINE'
           AND FLV07.lookup_code = GRB.attribute17
        ) sinka_class_name               --�V�ʐ��敪��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute18                --HHT���M�Ώۃt���O
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV08.meaning
       ,(SELECT FLV08.meaning
         FROM fnd_lookup_values FLV08  --�N�C�b�N�R�[�h(HHT���M�Ώۃt���O��)
         WHERE FLV08.language    = 'JA'
           AND FLV08.lookup_type = 'XXWIP_HHT_FLAG'
           AND FLV08.lookup_code = GRB.attribute18
        ) hht_flg_name                   --HHT���M�Ώۃt���O��
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute19                --�ŗL�L��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV09.meaning
       ,(SELECT FLV09.meaning
         FROM fnd_lookup_values FLV09  --�N�C�b�N�R�[�h(�ŗL�L����)
         WHERE FLV09.language    = 'JA'
           AND FLV09.lookup_type = 'XXCMN_PLANT_UNIQE_SIGN'
           AND FLV09.lookup_code = GRB.attribute19
        ) koyu_name                      --�ŗL�L����
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute20                --��ƕ���
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XLV.location_name              --��ƕ�����
       ,(SELECT XLV.location_name
         FROM xxsky_locations_v XLV    --���Ə����VIEW
         WHERE XLV.location_code = GRB.attribute20
        ) XLV_location_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,GRB.attribute21                --�[�i�q��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,IWM02.whse_name                --�[�i�q�ɖ�
       ,(SELECT IWM02.whse_name
         FROM ic_whse_mst IWM02  --�q��(�[�i�q�ɖ�)
         WHERE IWM02.whse_code = GRB.attribute21
        ) IWM02_whse_name
       --,FU_CB.user_name                --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE GRB.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( GRB.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE GRB.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( GRB.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE GRB.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  gmd_routings_b          GRB    --�H���}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,gmd_routings_tl         GRT    --�H���}�X�^(����)
       --,gmd_routing_class_tl    GRCT   --�H���敪�}�X�^���{��
       --,gmd_qc_status_tl        GQST   --
       --,ic_whse_mst             IWM01  --�q��(����於)
       --,mtl_item_locations      MIL    --OPM�ۊǏꏊ�}�X�^
       --,xxsky_locations_v       XLV    --���Ə����VIEW
       --,ic_whse_mst             IWM02  --�q��(�[�i�q�ɖ�)
       --,fnd_lookup_values       FLV01  --�N�C�b�N�R�[�h(���C���敪��)
       --,fnd_lookup_values       FLV02  --�N�C�b�N�R�[�h(�H��敪��)
       --,fnd_lookup_values       FLV03  --�N�C�b�N�R�[�h(�`�[�敪��)
       --,fnd_lookup_values       FLV04  --�N�C�b�N�R�[�h(���ъǗ�������)
       --,fnd_lookup_values       FLV05  --�N�C�b�N�R�[�h(���O�敪��)
       --,fnd_lookup_values       FLV06  --�N�C�b�N�R�[�h(�����i�敪��)
       --,fnd_lookup_values       FLV07  --�N�C�b�N�R�[�h(�V�ʐ��敪��)
       --,fnd_lookup_values       FLV08  --�N�C�b�N�R�[�h(HHT���M�Ώۃt���O��)
       --,fnd_lookup_values       FLV09  --�N�C�b�N�R�[�h(�ŗL�L����)
       --,fnd_user                FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins              FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  GRB.delete_mark        = 0
   AND  TRUNC(GRB.effective_start_date) <= TRUNC(SYSDATE)
   AND (TRUNC(GRB.effective_end_date)   >= TRUNC(SYSDATE)
           OR GRB.effective_end_date IS NULL)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  GRB.routing_id         = GRT.routing_id(+)
   --AND  GRT.language(+)        = 'JA'
   --AND  GRB.routing_class      = GRCT.routing_class(+)
   --AND  GRCT.language(+)       = 'JA'
   --AND  GQST.status_code(+)    = GRB.routing_status
   --AND  GQST.language(+)       = 'JA'
   --AND  GQST.entity_type(+)    = 'S'
   --AND  IWM01.whse_code(+)     = GRB.attribute3
   --AND  IWM02.whse_code(+)     = GRB.attribute21
   --AND  MIL.segment1(+)        = GRB.attribute9
   --AND  XLV.location_code(+)   = GRB.attribute20
   --AND  GRB.attribute21        = IWM02.whse_code(+)
   --AND  FLV01.language(+)      = 'JA'
   --AND  FLV01.lookup_type(+)   = 'XXCMN_PRODUCTION_LINE'
   --AND  FLV01.lookup_code(+)   = GRB.attribute2
   --AND  FLV02.language(+)      = 'JA'
   --AND  FLV02.lookup_type(+)   = 'XXCMN_K04'
   --AND  FLV02.lookup_code(+)   = GRB.attribute10
   --AND  FLV03.language(+)      = 'JA'
   --AND  FLV03.lookup_type(+)   = 'XXCMN_L03'
   --AND  FLV03.lookup_code(+)   = GRB.attribute13
   --AND  FLV04.language(+)      = 'JA'
   --AND  FLV04.lookup_type(+)   = 'XXCMN_L10'
   --AND  FLV04.lookup_code(+)   = GRB.attribute14
   --AND  FLV05.language(+)      = 'JA'
   --AND  FLV05.lookup_type(+)   = 'XXWIP_IN_OUT_TYPE'
   --AND  FLV05.lookup_code(+)   = GRB.attribute15
   --AND  FLV06.language(+)      = 'JA'
   --AND  FLV06.lookup_type(+)   = 'XXWIP_PROD_TYPE'
   --AND  FLV06.lookup_code(+)   = GRB.attribute16
   --AND  FLV07.language(+)      = 'JA'
   --AND  FLV07.lookup_type(+)   = 'XXWIP_NEW_LINE'
   --AND  FLV07.lookup_code(+)   = GRB.attribute17
   --AND  FLV08.language(+)      = 'JA'
   --AND  FLV08.lookup_type(+)   = 'XXWIP_HHT_FLAG'
   --AND  FLV08.lookup_code(+)   = GRB.attribute18
   --AND  FLV09.language(+)      = 'JA'
   --AND  FLV09.lookup_type(+)   = 'XXCMN_PLANT_UNIQE_SIGN'
   --AND  FLV09.lookup_code(+)   = GRB.attribute19
   --AND  GRB.created_by         = FU_CB.user_id(+)
   --AND  GRB.last_updated_by    = FU_LU.user_id(+)
   --AND  GRB.last_update_login  = FL_LL.login_id(+)
   --AND  FL_LL.user_id          = FU_LL.user_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKY_�H���}�X�^_����_V IS 'SKYLINK�p�H���}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�H���ԍ�                       IS '�H���ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�H����                         IS '�H����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�H������                       IS '�H������'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�L��_��                        IS '�L��_��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�L��_��                        IS '�L��_��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�敪                           IS '�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�敪��                         IS '�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.���C���敪                     IS '���C���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.���C���敪��                   IS '���C���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�X�e�[�^�X                     IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�X�e�[�^�X��                   IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�v�摹��                       IS '�v�摹��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.����                           IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�P��                           IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�����                         IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.����於                       IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.����                           IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�W���\��                       IS '�W���\��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.MIN�\��                        IS 'MIN�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.MAX�\��                        IS 'MAX�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�[�i�ꏊ                       IS '�[�i�ꏊ'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�[�i�ꏊ��                     IS '�[�i�ꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�H��敪                       IS '�H��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�H��敪��                     IS '�H��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�H������C���z����             IS '�H������C���z����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.���[�h�^�C��                   IS '���[�h�^�C��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�`�[�敪                       IS '�`�[�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�`�[�敪��                     IS '�`�[�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.���ъǗ�����                   IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.���ъǗ�������                 IS '���ъǗ�������'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.���O�敪                       IS '���O�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.���O�敪��                     IS '���O�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�����i�敪                     IS '�����i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�����i�敪��                   IS '�����i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�V�ʐ��敪                     IS '�V�ʐ��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�V�ʐ��敪��                   IS '�V�ʐ��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.HHT���M�Ώۃt���O              IS 'HHT���M�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.HHT���M�Ώۃt���O��            IS 'HHT���M�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�ŗL�L��                       IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�ŗL�L����                     IS '�ŗL�L����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.��ƕ���                       IS '��ƕ���'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.��ƕ�����                     IS '��ƕ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�[�i�q��                       IS '�[�i�q��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�[�i�q�ɖ�                     IS '�[�i�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�H���}�X�^_����_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
