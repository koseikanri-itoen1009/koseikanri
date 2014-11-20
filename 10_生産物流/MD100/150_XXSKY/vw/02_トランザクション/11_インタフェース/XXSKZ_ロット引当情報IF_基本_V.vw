/*************************************************************************
 * 
 * View  Name      : XXSKZ_���b�g�������IF_��{_V
 * Description     : XXSKZ_���b�g�������IF_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���b�g�������IF_��{_V
(
��Ж�
,�f�[�^���
,�`���p�}��
,�˗�NO
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���דE�v
,���b�gNO
,��������
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XLRI.corporation_name               --��Ж�
       ,XLRI.data_class                     --�f�[�^���
       ,XLRI.transfer_branch_no             --�`���p�}��
       ,XLRI.request_no                     --�˗�No
       ,XPCV.prod_class_code                --���i�敪
       ,XPCV.prod_class_name                --���i�敪��
       ,XICV.item_class_code                --�i�ڋ敪
       ,XICV.item_class_name                --�i�ڋ敪��
       ,XCCV.crowd_code                     --�Q�R�[�h
       ,XLRI.item_code                      --�i�ڃR�[�h
       ,XIMV.item_name                      --�i�ږ���
       ,XIMV.item_short_name                --�i�ڗ���
       ,XLRI.line_description               --���דE�v
       ,XLRI.lot_no                         --���b�gNo
       ,XLRI.reserved_quantity              --��������
       ,FU_CB.user_name                     --�쐬��
       ,TO_CHAR( XLRI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,TO_CHAR( XLRI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
  FROM  xxpo_lot_reserve_if XLRI            --���b�g�������C���^�[�t�F�[�X�A�h�I��
       ,xxskz_prod_class_v  XPCV            --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(���i�敪)
       ,xxskz_item_class_v  XICV            --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�i�ڋ敪)
       ,xxskz_crowd_code_v  XCCV            --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�Q�R�[�h)
       ,xxskz_item_mst_v    XIMV            --SKYLINK�p����VIEW OPM�i�ڏ��VIEW(�i�ږ�)
       ,fnd_user            FU_CB           --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user            FU_LU           --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user            FU_LL           --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins          FL_LL           --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XLRI.item_code          = XIMV.item_no(+)
   AND  XIMV.item_id            = XPCV.item_id(+)
   AND  XIMV.item_id            = XICV.item_id(+)
   AND  XIMV.item_id            = XCCV.item_id(+)
   AND  XLRI.created_by         = FU_CB.user_id(+)
   AND  XLRI.last_updated_by    = FU_LU.user_id(+)
   AND  XLRI.last_update_login  = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_���b�g�������IF_��{_V IS 'SKYLINK�p���b�g�������C���^�[�t�F�[�X�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.��Ж�             IS '��Ж�'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�f�[�^���         IS '�f�[�^���'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�`���p�}��         IS '�`���p�}��'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�˗�NO             IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�i�ڋ敪           IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�i�ڋ敪��         IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�Q�R�[�h           IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�i�ڃR�[�h         IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�i�ږ�             IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�i�ڗ���           IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.���דE�v           IS '���דE�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.���b�gNO           IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.��������           IS '��������'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���b�g�������IF_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/
