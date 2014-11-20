CREATE OR REPLACE VIEW APPS.XXSKY_�o�������я��IF_��{_V
(
 ��Ж�
,�f�[�^���
,�`���p�}��
,���Y��
,�����R�[�h
,����於
,�H��R�[�h
,�H�ꖼ
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,������
,�ŗL�L��
,�o��������
,�E�v
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        XVSTI.corporation_name                          --��Ж�
       ,XVSTI.data_class                                --�f�[�^���
       ,XVSTI.transfer_branch_no                        --�`���p�}��
       ,XVSTI.manufactured_date                         --���Y��
       ,XVSTI.vendor_code                               --�����R�[�h
       ,XV2V.vendor_name                                --����於
       ,XVSTI.factory_code                              --�H��R�[�h
       ,XVS2V.vendor_site_name                          --�H�ꖼ
       ,XPCV.prod_class_code                            --���i�敪
       ,XPCV.prod_class_name                            --���i�敪��
       ,XICV.item_class_code                            --�i�ڋ敪
       ,XICV.item_class_name                            --�i�ڋ敪��
       ,XCCV.crowd_code                                 --�Q�R�[�h
       ,XVSTI.item_code                                 --�i�ڃR�[�h
       ,XIM2V.item_name                                 --�i�ږ�
       ,XIM2V.item_short_name                           --�i�ڗ���
       ,XVSTI.producted_date                            --������
       ,XVSTI.koyu_code                                 --�ŗL�L��
       ,XVSTI.producted_quantity                        --�o��������
       ,XVSTI.description                               --�E�v
       ,FU_CB.user_name         created_by_name         --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XVSTI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date           --�쐬����
       ,FU_LU.user_name         last_updated_by_name    --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XVSTI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date        --�X�V����
       ,FU_LL.user_name         last_update_login_name  --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxpo_vendor_supply_txns_if  XVSTI               --�o�������я��C���^�t�F�[�X�A�h�I��
       ,xxsky_vendors2_v            XV2V                --SKYLINK�p����VIEW �����R�[�h�擾VIEW
       ,xxsky_vendor_sites2_v       XVS2V               --SKYLINK�p����VIEW �H��R�[�h�擾VIEW
       ,xxsky_prod_class_v          XPCV                --SKYLINK�p����VIEW ���i�敪�擾VIEW
       ,xxsky_item_class_v          XICV                --SKYLINK�p����VIEW �i�ڏ��i�敪�擾VIEW
       ,xxsky_crowd_code_v          XCCV                --SKYLINK�p����VIEW �Q�R�[�h�擾VIEW
       ,xxsky_item_mst2_v           XIM2V               --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2
       ,fnd_user                    FU_CB               --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                    FU_LU               --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                    FU_LL               --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                  FL_LL               --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XVSTI.vendor_code           =  XV2V.segment1(+)
   AND  XVSTI.manufactured_date     >= XV2V.start_date_active(+)
   AND  XVSTI.manufactured_date     <= XV2V.end_date_active(+)
   AND  XVSTI.factory_code          =  XVS2V.vendor_site_code(+)
   AND  XVSTI.manufactured_date     >= XVS2V.start_date_active(+)
   AND  XVSTI.manufactured_date     <= XVS2V.end_date_active(+)
   AND  XVSTI.item_code             =  XIM2V.item_no(+)
   AND  XVSTI.manufactured_date     >= XIM2V.start_date_active(+)
   AND  XVSTI.manufactured_date     <= XIM2V.end_date_active(+)
   AND  XIM2V.item_id               =  XPCV.item_id(+)
   AND  XIM2V.item_id               =  XICV.item_id(+)
   AND  XIM2V.item_id               =  XCCV.item_id(+)
   --WHO�J�����擾
   AND  XVSTI.created_by            =  FU_CB.user_id(+)
   AND  XVSTI.last_updated_by       =  FU_LU.user_id(+)
   AND  XVSTI.last_update_login     =  FL_LL.login_id(+)
   AND  FL_LL.user_id               =  FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�o�������я��IF_��{_V                     IS 'SKYLINK�p�o�������я��IF�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.��Ж�             IS '��Ж�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�f�[�^���         IS '�f�[�^���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�`���p�}��         IS '�`���p�}��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.���Y��             IS '���Y��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�����R�[�h       IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.����於           IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�H��R�[�h         IS '�H��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�H�ꖼ             IS '�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�i�ڋ敪           IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�i�ڋ敪��         IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�Q�R�[�h           IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�i�ڃR�[�h         IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�i�ږ�             IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�i�ڗ���           IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.������             IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�ŗL�L��           IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�o��������         IS '�o��������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�E�v               IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�������я��IF_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/