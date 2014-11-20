CREATE OR REPLACE VIEW APPS.XXSKY_�I������_��{_V
(
 �񍐕����R�[�h
,�񍐕�����
,�I���N��
,�I����
,�I���q�ɃR�[�h
,�I���q�ɖ�
,�ۊǏꏊ�R�[�h
,�ۊǏꏊ��
,�I���A��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�gNO
,������
,�ܖ�����
,�ŗL�L��
,�I���P�[�X��
,����
,�I���o��
,���P�[�V����
,���b�NNO�P
,���b�NNO�Q
,���b�NNO�R
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��)
AS
SELECT  XSIR.report_post_code               --�񍐕����R�[�h
       ,XLV.location_name                   --�񍐕�����
       ,TO_CHAR( XSIR.invent_date, 'YYYYMM' )
                                            --�I���N��
       ,XSIR.invent_date                    --�I����
       ,XSIR.invent_whse_code               --�I���q�ɃR�[�h
       ,IWM.whse_name                       --�I���q�ɖ�
       ,XILV.segment1        location_code  --�ۊǏꏊ�R�[�h
       ,XILV.description     location_name  --�ۊǏꏊ��
       ,XSIR.invent_seq                     --�I���A��
       ,XPCV.prod_class_code                --���i�敪
       ,XPCV.prod_class_name                --���i�敪��
       ,XICV.item_class_code                --�i�ڋ敪
       ,XICV.item_class_name                --�i�ڋ敪��
       ,XCCV.crowd_code                     --�Q�R�[�h
       ,XSIR.item_code                      --�i�ڃR�[�h
       ,XIMV.item_name                      --�i�ږ�
       ,XIMV.item_short_name                --�i�ڗ���
       ,XSIR.lot_no                         --���b�gNo
       ,XSIR.maker_date                     --������
       ,XSIR.limit_date                     --�ܖ�����
       ,XSIR.proper_mark                    --�ŗL�L��
       ,XSIR.case_amt                       --�I���P�[�X��
       ,XSIR.content                        --����
       ,XSIR.loose_amt                      --�I���o��
       ,XSIR.location                       --���P�[�V����
       ,XSIR.rack_no1                       --���b�NNo�P
       ,XSIR.rack_no2                       --���b�NNo�Q
       ,XSIR.rack_no3                       --���b�NNo�R
       ,FU_CB.user_name                     --�쐬��
       ,TO_CHAR( XSIR.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,TO_CHAR( XSIR.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
FROM    xxinv_stc_inventory_result  XSIR    --�I�����ʃA�h�I��
       ,xxsky_locations2_v          XLV     --���Ə��i�񍐕����j���擾
       ,ic_whse_mst                 IWM     --�q�ɖ��擾
       ,xxsky_item_locations_v      XILV    --�ۊǏꏊ�擾�p
       ,xxsky_item_mst2_v           XIMV    --�i�ڎ擾
       ,xxsky_prod_class_v          XPCV    --���i�敪�擾
       ,xxsky_item_class_v          XICV    --�i�ڋ敪�擾
       ,xxsky_crowd_code_v          XCCV    --�Q�R�[�h�擾
       ,fnd_user                    FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                    FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                    FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                  FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
--���Ə��i�񍐕����j���擾����
      XLV.location_code(+) = XSIR.report_post_code
  AND XLV.start_date_active(+) <= XSIR.invent_date
  AND XLV.end_date_active(+)   >= XSIR.invent_date
--�q�ɖ��擾����
  AND XSIR.invent_whse_code = IWM.whse_code(+)
  --�ۊǏꏊ���擾����
  AND XILV.allow_pickup_flag(+) = '1'                  --�o�׈����Ώۃt���O
  AND XSIR.invent_whse_code     = XILV.whse_code(+)
--�i�ڎ擾����
  AND XIMV.item_id(+) = XSIR.item_id
  AND XIMV.start_date_active(+) <= XSIR.invent_date
  AND XIMV.end_date_active(+)   >= XSIR.invent_date
--���i�敪�擾����
  AND XPCV.item_id(+) = XSIR.item_id
--�i�ڋ敪�擾����
  AND XICV.item_id(+) = XSIR.item_id
--�Q�R�[�h�擾����
  AND XCCV.item_id(+) = XSIR.item_id
--���[�U�[�}�X�^(CREATED_BY���̎擾�p����)
  AND  FU_CB.user_id(+)  = XSIR.created_by
--���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p����)
  AND  FU_LU.user_id(+)  = XSIR.last_updated_by
--���O�C���}�X�^�E���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p����)
  AND  FL_LL.login_id(+) = XSIR.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�I������_��{_V IS 'XXSKY_�I������ (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�񍐕����R�[�h   IS '�񍐕����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�񍐕�����       IS '�񍐕�����'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�I���N��         IS '�I���N��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�I����           IS '�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�I���q�ɃR�[�h   IS '�I���q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�I���q�ɖ�       IS '�I���q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�ۊǏꏊ�R�[�h   IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�ۊǏꏊ��       IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�I���A��         IS '�I���A��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.���i�敪         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.���i�敪��       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�i�ڋ敪         IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�i�ڋ敪��       IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�Q�R�[�h         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�i�ڃR�[�h       IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�i�ږ�           IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�i�ڗ���         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.���b�gNO         IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.������           IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�ܖ�����         IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�ŗL�L��         IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�I���P�[�X��     IS '�I���P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.����             IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�I���o��         IS '�I���o��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.���P�[�V����     IS '���P�[�V����'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.���b�NNO�P       IS '���b�NNo�P'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.���b�NNO�Q       IS '���b�NNo�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.���b�NNO�R       IS '���b�NNo�R'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�I������_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
