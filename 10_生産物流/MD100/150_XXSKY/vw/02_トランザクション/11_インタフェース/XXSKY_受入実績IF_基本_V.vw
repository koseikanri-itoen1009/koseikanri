CREATE OR REPLACE VIEW APPS.XXSKY_�������IF_��{_V
(
�������ԍ�
,�����R�[�h
,����於
,�[����
,�[����R�[�h
,�[���於
,���������הԍ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ���
,�i�ڗ���
,���b�gNO
,������
,�ŗL�L��
,�w������
,���דE�v
,�����
,�������
,�P�ʃR�[�h
,������דE�v
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        XRTI.source_document_number      --�������ԍ�
       ,XRTI.vendor_code                 --�����R�[�h
       ,XRTI.vendor_name                 --����於
       ,XRTI.promised_date               --�[����
       ,XRTI.location_code               --�[����R�[�h
       ,XRTI.location_name               --�[���於
       ,XRTI.source_document_line_num    --���������הԍ�
       ,XPCV.prod_class_code             --���i�敪
       ,XPCV.prod_class_name             --���i�敪��
       ,XICV.item_class_code             --�i�ڋ敪
       ,XICV.item_class_name             --�i�ڋ敪��
       ,XCCV.crowd_code                  --�Q�R�[�h
       ,XRTI.item_code                   --�i�ڃR�[�h
       ,XRTI.item_name                   --�i�ږ���
       ,XIM2V.item_short_name            --�i�ڗ���
       ,XRTI.lot_number                  --���b�gNo
       ,XRTI.producted_date              --������
       ,XRTI.koyu_code                   --�ŗL�L��
       ,XRTI.quantity                    --�w������
       ,XRTI.po_line_description         --���דE�v
       ,XRTI.rcv_date                    --�����
       ,XRTI.rcv_quantity                --�������
       ,XRTI.rcv_quantity_uom            --�P�ʃR�[�h
       ,XRTI.rcv_line_description        --������דE�v
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( XRTI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( XRTI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM  xxpo_rcv_txns_interface XRTI     --������уC���^�[�t�F�[�X
       ,xxsky_prod_class_v      XPCV     --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(���i�敪)
       ,xxsky_item_class_v      XICV     --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�i�ڋ敪)
       ,xxsky_crowd_code_v      XCCV     --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�Q�R�[�h)
       ,xxsky_item_mst2_v       XIM2V    --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ږ�)
       ,fnd_user                FU_CB    --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU    --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL    --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL    --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XRTI.item_code             = XIM2V.item_no(+)
   AND  XIM2V.start_date_active(+) <= XRTI.promised_date
   AND  XIM2V.end_date_active(+)   >= XRTI.promised_date
   AND  XIM2V.item_id              = XPCV.item_id(+)
   AND  XIM2V.item_id              = XICV.item_id(+)
   AND  XIM2V.item_id              = XCCV.item_id(+)
   AND  XRTI.created_by            = FU_CB.user_id(+)
   AND  XRTI.last_updated_by       = FU_LU.user_id(+)
   AND  XRTI.last_update_login     = FL_LL.login_id(+)
   AND  FL_LL.user_id              = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�������IF_��{_V IS 'SKYLINK�p������уC���^�[�t�F�[�X�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�������ԍ�       IS '�������ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�����R�[�h     IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.����於         IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�[����           IS '�[����'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�[����R�[�h     IS '�[����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�[���於         IS '�[���於'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.���������הԍ�   IS '���������הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.���i�敪         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.���i�敪��       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�i�ڋ敪         IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�i�ڋ敪��       IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�Q�R�[�h         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�i�ڃR�[�h       IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�i�ږ���         IS '�i�ږ���'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�i�ڗ���         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.���b�gNO         IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.������           IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�ŗL�L��         IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�w������         IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.���דE�v         IS '���דE�v'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�����           IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�������         IS '�������'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�P�ʃR�[�h       IS '�P�ʃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.������דE�v     IS '������דE�v'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�������IF_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
