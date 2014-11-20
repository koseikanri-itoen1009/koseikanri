CREATE OR REPLACE VIEW APPS.XXSKY_�W������_��{_V
(
 ���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�q�ɃR�[�h
,�q�ɖ�
,�J�����_
,�J�����_��
,����
,���Ԗ�
,�L���J�n��
,�L���I����
,�������@
,�������@��
,�R���|�[�l���g�敪��
,���̓R�[�h
,���̓R�[�h��
,�R���|�[�l���g����
,�m��t���O
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        XPCV.prod_class_code           --���i�敪
       ,XPCV.prod_class_name           --���i�敪��
       ,XICV.item_class_code           --�i�ڋ敪
       ,XICV.item_class_name           --�i�ڋ敪��
       ,XCCV.crowd_code                --�Q�R�[�h
       ,XIMV.item_no                   --�i�ڃR�[�h
       ,XIMV.item_name                 --�i�ږ�
       ,XIMV.item_short_name           --�i�ڗ���
       ,CCD.whse_code                  --�q�ɃR�[�h
       ,IWM.whse_name                  --�q�ɖ�
       ,CCD.calendar_code              --�J�����_
       ,CCHT.calendar_desc             --�J�����_��
       ,CCD.period_code                --����
       ,CCDD.period_desc               --���Ԗ�
       ,TRUNC( CCDD.start_date )       --�L���J�n��
       ,TRUNC( CCDD.end_date )         --�L���I����
       ,CCD.cost_mthd_code             --�������@
       ,CMM.cost_mthd_desc             --�������@��
       ,CCMT.cost_cmpntcls_desc        --�R���|�[�l���g�敪��
       ,CCD.cost_analysis_code         --���̓R�[�h
       ,CAM.cost_analysis_desc         --���̓R�[�h��
       ,CCD.cmpnt_cost                 --�R���|�[�l���g����
       ,CCD.rollover_ind               --�m��t���O
       ,FU_CB.user_name                --�쐬��
       ,TO_CHAR( CCD.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --�쐬��
       ,FU_LU.user_name                --�ŏI�X�V��
       ,TO_CHAR( CCD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                       --�ŏI�X�V��
       ,FU_LL.user_name                --�ŏI�X�V���O�C��
  FROM  cm_cmpt_dtl         CCD       --�i�ڌ����}�X�^
       ,xxsky_prod_class_v  XPCV      --SKYLINK�p OPM�i�ڋ敪VIEW(���i�敪)
       ,xxsky_item_class_v  XICV      --SKYLINK�p OPM�i�ڋ敪VIEW(�i�ڋ敪)
       ,xxsky_crowd_code_v  XCCV      --SKYLINK�p OPM�i�ڋ敪VIEW(�Q�R�[�h)
       ,xxsky_item_mst_v    XIMV      --OPM�i�ڏ��VIEW
       ,ic_whse_mst         IWM       --OPM�q�Ƀ}�X�^
       ,cm_cldr_hdr_tl      CCHT      --�J�����_
       ,cm_cldr_dtl         CCDD      --����
       ,cm_mthd_mst         CMM       --����
       ,cm_cmpt_mst_tl      CCMT      --�R���|�[�l���g
       ,cm_alys_mst         CAM       --����
       ,fnd_user            FU_CB     --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user            FU_LU     --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user            FU_LL     --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins          FL_LL     --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  CCD.item_id = XPCV.item_id(+)
   AND  CCD.item_id = XICV.item_id(+)
   AND  CCD.item_id = XCCV.item_id(+)
   AND  CCD.item_id = XIMV.item_id(+)
   AND  CCD.whse_code = IWM.whse_code(+)
   AND  CCD.calendar_code = CCHT.calendar_code(+)
   AND  CCHT.language(+) = 'JA'
   AND  CCD.calendar_code = CCDD.calendar_code(+)
   AND  CCD.period_code   = CCDD.period_code(+)
   AND  CCD.cost_mthd_code = CMM.cost_mthd_code(+)
   AND  CCD.cost_cmpntcls_id = CCMT.cost_cmpntcls_id(+)
   AND  CCMT.language(+) = 'JA'
   AND  CCD.cost_analysis_code = CAM.cost_analysis_code(+)
   AND  CCD.created_by        = FU_CB.user_id(+)
   AND  CCD.last_updated_by   = FU_LU.user_id(+)
   AND  CCD.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�W������_��{_V IS 'SKYLINK�p�W�������i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.���i�敪             IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.���i�敪��           IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�i�ڋ敪             IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�i�ڋ敪��           IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�Q�R�[�h             IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�i�ڃR�[�h           IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�i�ږ�               IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�i�ڗ���             IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�q�ɃR�[�h           IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�q�ɖ�               IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�J�����_             IS '�J�����_'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�J�����_��           IS '�J�����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.����                 IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.���Ԗ�               IS '���Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�L���J�n��           IS '�L���J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�L���I����           IS '�L���I����'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�������@             IS '�������@'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�������@��           IS '�������@��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�R���|�[�l���g�敪�� IS '�R���|�[�l���g�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.���̓R�[�h           IS '���̓R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.���̓R�[�h��         IS '���̓R�[�h��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�R���|�[�l���g����   IS '�R���|�[�l���g����'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�m��t���O           IS '�m��t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������_��{_V.�ŏI�X�V���O�C��     IS '�ŏI�X�V���O�C��'
/