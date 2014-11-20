CREATE OR REPLACE VIEW APPS.XXSKY_�o��������IF_��{_V
(
 �v�����g�R�[�h
,�v�����g��
,��zNO
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�o�������ѐ�
,������ѓ�
,���Y��
,������
,�ܖ�������
)
AS
SELECT 
        XVAI.plant_code                  --�v�����g�R�[�h
       ,SOMT.orgn_name                   --�v�����g��
       ,XVAI.batch_no                    --��zNo
       ,XPCV.prod_class_code             --���i�敪
       ,XPCV.prod_class_name             --���i�敪��
       ,XICV.item_class_code             --�i�ڋ敪
       ,XICV.item_class_name             --�i�ڋ敪��
       ,XCCV.crowd_code                  --�Q�R�[�h
       ,XVAI.item_code                   --�i�ڃR�[�h
       ,XIM2V.item_name                  --�i�ږ�
       ,XIM2V.item_short_name            --�i�ڗ���
       ,XVAI.volume_actual_qty           --�o�������ѐ�
       ,XVAI.rcv_date                    --������ѓ�
       ,XVAI.actual_date                 --���Y��
       ,XVAI.maker_date                  --������
       ,XVAI.expiration_date             --�ܖ�������
  FROM  xxwip_volume_actual_if  XVAI     --�o�������уC���^�t�F�[�X
       ,sy_orgn_mst_b           SOMB     --OPM�v�����g�}�X�^
       ,sy_orgn_mst_tl          SOMT     --
       ,xxsky_prod_class_v      XPCV     --SKYLINK�p����VIEW ���i�敪�擾VIEW
       ,xxsky_item_class_v      XICV     --SKYLINK�p����VIEW �i�ڏ��i�敪�擾VIEW
       ,xxsky_crowd_code_v      XCCV     --SKYLINK�p����VIEW �Q�R�[�h�擾VIEW
       ,xxsky_item_mst2_v       XIM2V    --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2
 WHERE  XVAI.plant_code  =  SOMB.orgn_code(+)
   AND  SOMB.orgn_code   =  SOMT.orgn_code(+)
   AND  SOMT.language(+) =  'JA'
   AND  XVAI.item_code   =  XIM2V.item_no(+)
   AND  XVAI.rcv_date    >= XIM2V.start_date_active(+)
   AND  XVAI.rcv_date    <= XIM2V.end_date_active(+)
   AND  XIM2V.item_id    =  XPCV.item_id(+)
   AND  XIM2V.item_id    =  XICV.item_id(+)
   AND  XIM2V.item_id    =  XCCV.item_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�o��������IF_��{_V                 IS 'SKYLINK�p�o��������IF�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�v�����g�R�[�h IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�v�����g��     IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.��zNO         IS '��zNo'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.���i�敪       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.���i�敪��     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�i�ڋ敪       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�i�ڋ敪��     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�Q�R�[�h       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�i�ڃR�[�h     IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�i�ږ�         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�i�ڗ���       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�o�������ѐ�   IS '�o�������ѐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.������ѓ�     IS '������ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.���Y��         IS '���Y��'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.������         IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�o��������IF_��{_V.�ܖ�������     IS '�ܖ�������'
/