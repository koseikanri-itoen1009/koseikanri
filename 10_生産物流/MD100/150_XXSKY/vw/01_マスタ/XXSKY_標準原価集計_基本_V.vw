CREATE OR REPLACE VIEW APPS.XXSKY_�W�������W�v_��{_V
(
 ���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�L���J�n��
,�L���I����
,�W�v����
,������
,�Đ���
,���ޔ�
,���
,�O�����H��
,�ۊǔ�
,���̑��o��
,FM���[�g�p
,�\���P
,�\���Q
,�\���R
)
AS
SELECT
        PRODC.prod_class_code           prod_class_code               --���i�敪
       ,PRODC.prod_class_name           prod_class_name               --���i�敪��
       ,ITEMC.item_class_code           item_class_code               --�i�ڋ敪
       ,ITEMC.item_class_name           item_class_name               --�i�ڋ敪��
       ,CROWD.crowd_code                crowd_code                    --�Q�R�[�h
       ,ITEM.item_no                    item_no                       --�i�ڃR�[�h
       ,ITEM.item_name                  item_name                     --�i�ږ�
       ,ITEM.item_short_name            item_short_name               --�i�ڗ���
       ,TRUNC( SCCD.start_date )        start_date                    --�L���J�n��
       ,TRUNC( SCCD.end_date )          end_date                      --�L���I����
       ,NVL( SCCD.cost_all, 0 )         cost_all                      --�W�v����
       ,NVL( SCCD.cost_gen, 0 )         cost_gen                      --������
       ,NVL( SCCD.cost_sai, 0 )         cost_sai                      --�Đ���
       ,NVL( SCCD.cost_szi, 0 )         cost_szi                      --���ޔ�
       ,NVL( SCCD.cost_hou, 0 )         cost_hou                      --���
       ,NVL( SCCD.cost_gai, 0 )         cost_gai                      --�O�����H��
       ,NVL( SCCD.cost_hkn, 0 )         cost_hkn                      --�ۊǔ�
       ,NVL( SCCD.cost_kei, 0 )         cost_kei                      --���̑��o��
       ,NVL( SCCD.cost_fm , 0 )         cost_fm                       --FM���[�g�p
       ,NVL( SCCD.cost_yb1, 0 )         cost_yb1                      --�\���P
       ,NVL( SCCD.cost_yb2, 0 )         cost_yb2                      --�\���Q
       ,NVL( SCCD.cost_yb3, 0 )         cost_yb3                      --�\���R
  FROM (
          -------------------------------------------------------
          -- ���ԁA�q�ɁA�i�ڒP�ʂŏW�v���������擾
          -------------------------------------------------------
          SELECT
                  CCD.item_id                     item_id             --�i��ID
                 ,CCDD.start_date                 start_date          --�L���J�n��
                 ,CCDD.end_date                   end_date            --�L���I����
                 ,SUM( CCD.cmpnt_cost )           cost_all            --�W�v����
                  --�R���|�[�l���g�����P�ʂō��ڕ\�����s�Ȃ�
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '01GEN' THEN CCD.cmpnt_cost END )  cost_gen  --������
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '02SAI' THEN CCD.cmpnt_cost END )  cost_sai  --�Đ���
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '03SZI' THEN CCD.cmpnt_cost END )  cost_szi  --���ޔ�
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '04HOU' THEN CCD.cmpnt_cost END )  cost_hou  --���
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '05GAI' THEN CCD.cmpnt_cost END )  cost_gai  --�O�����H��
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '06HKN' THEN CCD.cmpnt_cost END )  cost_hkn  --�ۊǔ�
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '07KEI' THEN CCD.cmpnt_cost END )  cost_kei  --���̑��o��
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '99FM'  THEN CCD.cmpnt_cost END )  cost_fm   --FM���[�g�p
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '08YB1' THEN CCD.cmpnt_cost END )  cost_yb1  --�\���P
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '09YB2' THEN CCD.cmpnt_cost END )  cost_yb2  --�\���Q
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '10YB3' THEN CCD.cmpnt_cost END )  cost_yb3  --�\���R
            FROM
                  cm_cmpt_dtl                     CCD                 --�i�ڌ����}�X�^
                 ,cm_cmpt_mst_b                   CCMB                --�R���|�[�l���g�}�X�^
                 ,cm_cldr_dtl                     CCDD                --�����J�����_
           WHERE
             --�i�ڌ����}�X�^�̒��o����(Unique�L�[���i���Ă���)
                  CCD.whse_code                   = '000'             --�q��(�����q��)
             AND  CCD.cost_mthd_code              = 'STDU'            --�������@�R�[�h
             AND  CCD.cost_analysis_code          = '0000'            --���̓R�[�h
             AND  CCD.cost_level                  = 0                 --�R�X�g���x��
             AND  CCD.rollover_ind                = 0                 --�m��t���O
             AND  CCD.delete_mark                 = 0                 --�폜�t���O
             --�R���|�[�l���g�}�X�^���擾
             AND  CCD.cost_cmpntcls_id            = CCMB.cost_cmpntcls_id
             --�����J�����_���擾
             AND  CCD.calendar_code               = CCDD.calendar_code
             AND  CCD.period_code                 = CCDD.period_code
          GROUP BY
                  CCD.item_id                     --�i��ID
                 ,CCDD.start_date                 --�L���J�n��
                 ,CCDD.end_date                   --�L���I����
       )                           SCCD           --�����W�v���
       ,xxsky_item_mst2_v          ITEM           --�i�ڏ��擾�p
       ,xxsky_prod_class_v         PRODC          --���i�敪�擾�p
       ,xxsky_item_class_v         ITEMC          --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v         CROWD          --�Q�R�[�h�擾�p
 WHERE
   --�i�ڏ��擾 (�����L���I�������_�ŗL���ȕi�ڏ����擾���鎖�Ƃ���)
        SCCD.item_id               = ITEM.item_id(+)
   AND  TRUNC( SCCD.end_date )    >= ITEM.start_date_active(+)
   AND  TRUNC( SCCD.end_date )    <= ITEM.end_date_active(+)
   --�i�ڃJ�e�S�����擾
   AND  SCCD.item_id               = PRODC.item_id(+)
   AND  SCCD.item_id               = ITEMC.item_id(+)
   AND  SCCD.item_id               = CROWD.item_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�W�������W�v_��{_V IS 'SKYLINK�p�W�������W�v�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.���i�敪   IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�i�ڋ敪   IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�Q�R�[�h   IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�i�ږ�     IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�i�ڗ���   IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�L���J�n�� IS '�L���J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�L���I���� IS '�L���I����'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�W�v����   IS '�W�v����'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.������     IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�Đ���     IS '�Đ���'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.���ޔ�     IS '���ޔ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.���     IS '���'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�O�����H�� IS '�O�����H��'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�ۊǔ�     IS '�ۊǔ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.���̑��o�� IS '���̑��o��'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.FM���[�g�p IS 'FM���[�g�p'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�\���P     IS '�\���P'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�\���Q     IS '�\���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�W�������W�v_��{_V.�\���R     IS '�\���R'
/
