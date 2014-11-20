CREATE OR REPLACE VIEW APPS.XXSKY_�����\���\_����_V
(
 ���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���_�R�[�h
,���_��
,�z����R�[�h
,�z���於
,�K�p�J�n��
,�K�p�I����
,�o�וۊǑq�ɃR�[�h
,�o�וۊǑq�ɖ�
,�ړ����ۊǑq�ɃR�[�h�P
,�ړ����ۊǑq�ɖ��P
,�ړ����ۊǑq�ɃR�[�h�Q
,�ړ����ۊǑq�ɖ��Q
,�d����T�C�g�R�[�h�P
,�d����T�C�g���P
,�d����T�C�g�R�[�h�Q
,�d����T�C�g���Q
,�v�揤�i�t���O
,�v�揤�i�t���O��
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
       ,XSR.item_code                  --�i�ڃR�[�h
       ,XIMV.item_name                 --�i�ږ�
       ,XIMV.item_short_name           --�i�ڗ���
       ,XSR.base_code                  --���_�R�[�h
       ,XCAV.party_name                --���_��
       ,XSR.ship_to_code               --�z����R�[�h
       ,XPSV.party_site_name           --�z���於
       ,XSR.start_date_active          --�K�p�J�n��
       ,XSR.end_date_active            --�K�p�I����
       ,XSR.delivery_whse_code         --�o�וۊǑq�ɃR�[�h
       ,XILV01.description             --�o�וۊǑq�ɖ�
       ,XSR.move_from_whse_code1       --�ړ����ۊǑq�ɃR�[�h�P
       ,XILV02.description             --�ړ����ۊǑq�ɖ��P
       ,XSR.move_from_whse_code2       --�ړ����ۊǑq�ɃR�[�h�Q
       ,XILV03.description             --�ړ����ۊǑq�ɖ��Q
       ,XSR.vendor_site_code1          --�d����T�C�g�R�[�h�P
       ,XVSV01.vendor_site_name        --�d����T�C�g���P
       ,XSR.vendor_site_code2          --�d����T�C�g�R�[�h�Q
       ,XVSV02.vendor_site_name        --�d����T�C�g���Q
       ,XSR.plan_item_flag             --�v�揤�i�t���O
       ,DECODE(XSR.plan_item_flag, '0', '�v�揤�i��Ώ�', '1', '�v�揤�i�Ώ�')
        plan_item_flag_name            --�v�揤�i�t���O��
       ,FU_CB.user_name                --�쐬��
       ,TO_CHAR( XSR.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�쐬��
       ,FU_LU.user_name                --�ŏI�X�V��
       ,TO_CHAR( XSR.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�ŏI�X�V��
       ,FU_LL.user_name                --�ŏI�X�V���O�C��
  FROM  xxcmn_sourcing_rules    XSR    --�����\���A�h�I���}�X�^
       ,xxsky_item_mst_v        XIMV   --OPM�i�ڏ��VIEW
       ,xxsky_prod_class_v      XPCV   --SKYLINK�p OPM�i�ڋ敪VIEW(���i�敪)
       ,xxsky_item_class_v      XICV   --SKYLINK�p OPM�i�ڋ敪VIEW(�i�ڋ敪)
       ,xxsky_crowd_code_v      XCCV   --SKYLINK�p OPM�i�ڋ敪VIEW(�Q�R�[�h)
       ,xxsky_cust_accounts_v   XCAV   --�ڋq���VIEW(���_)
       ,xxsky_party_sites_v     XPSV   --�z������VIEW(�z����)
       ,xxsky_item_locations_v  XILV01 --OPM�ۊǏꏊ���VIEW(�o�וۊǑq��)
       ,xxsky_item_locations_v  XILV02 --�q��(�ړ����ۊǑq�ɂP)
       ,xxsky_item_locations_v  XILV03 --�q��(�ړ����ۊǑq�ɂQ)
       ,xxsky_vendor_sites_v    XVSV01 --�d����T�C�g���VIEW(�d����T�C�g�P)
       ,xxsky_vendor_sites_v    XVSV02 --�d����T�C�g���VIEW(�d����T�C�g�Q)
       ,fnd_user                FU_CB  --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU  --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL  --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL  --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XSR.start_date_active <= TRUNC(SYSDATE)
   AND  XSR.end_date_active   >= TRUNC(SYSDATE)
   AND  XSR.item_code = XIMV.item_no(+)
   AND  XIMV.item_id  = XPCV.item_id(+)
   AND  XIMV.item_id  = XICV.item_id(+)
   AND  XIMV.item_id  = XCCV.item_id(+)
   AND  XSR.base_code = XCAV.party_number(+)
   AND  XSR.ship_to_code = XPSV.party_site_number(+)
   AND  XSR.delivery_whse_code = XILV01.segment1(+)
   AND  XSR.move_from_whse_code1 = XILV02.segment1(+)
   AND  XSR.move_from_whse_code2 = XILV03.segment1(+)
   AND  XSR.vendor_site_code1 =  XVSV01.vendor_site_code(+)
   AND  XSR.vendor_site_code2 =  XVSV02.vendor_site_code(+)
   AND  XSR.created_by        = FU_CB.user_id(+)
   AND  XSR.last_updated_by   = FU_LU.user_id(+)
   AND  XSR.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�����\���\_����_V IS 'SKYLINK�p�����\���\�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.���i�敪              IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.���i�敪��            IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�i�ڋ敪              IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�i�ڋ敪��            IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�Q�R�[�h              IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�i�ڃR�[�h            IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�i�ږ�                IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�i�ڗ���              IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.���_�R�[�h            IS '���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.���_��                IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�z����R�[�h          IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�z���於              IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�K�p�J�n��            IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�K�p�I����            IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�o�וۊǑq�ɃR�[�h    IS '�o�וۊǑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�o�וۊǑq�ɖ�        IS '�o�וۊǑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�ړ����ۊǑq�ɃR�[�h�P  IS '�ړ����ۊǑq�ɃR�[�h�P'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�ړ����ۊǑq�ɖ��P      IS '�ړ����ۊǑq�ɖ��P'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�ړ����ۊǑq�ɃR�[�h�Q  IS '�ړ����ۊǑq�ɃR�[�h�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�ړ����ۊǑq�ɖ��Q      IS '�ړ����ۊǑq�ɖ��Q'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�d����T�C�g�R�[�h�P    IS '�d����T�C�g�R�[�h�P'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�d����T�C�g���P        IS '�d����T�C�g���P'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�d����T�C�g�R�[�h�Q    IS '�d����T�C�g�R�[�h�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�d����T�C�g���Q        IS '�d����T�C�g���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�v�揤�i�t���O        IS '�v�揤�i�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�v�揤�i�t���O��      IS '�v�揤�i�t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�����\���\_����_V.�ŏI�X�V���O�C��      IS '�ŏI�X�V���O�C��'
/