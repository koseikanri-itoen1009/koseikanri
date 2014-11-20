/*************************************************************************
 * 
 * View  Name      : XXSKZ_�I�����ʏW�v_��{_V
 * Description     : XXSKZ_�I�����ʏW�v_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�I�����ʏW�v_��{_V
(
 �I���N��
,�I���q�ɃR�[�h
,�I���q�ɖ�
,�ۊǏꏊ�R�[�h
,�ۊǏꏊ��
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
,�I���P�[�X�����v
,����
,�I���o�������v
)
AS
SELECT  TO_CHAR( XSIR.invent_date, 'YYYYMM' )        --�I���N��
       ,XSIR.invent_whse_code                        --�I���q�ɃR�[�h
       ,IWM.whse_name                                --�I���q�ɖ�
       ,XILV.segment1               location_code    --�ۊǏꏊ�R�[�h
       ,XILV.description            location_name    --�ۊǏꏊ��
       ,XPCV.prod_class_code                         --���i�敪
       ,XPCV.prod_class_name                         --���i�敪��
       ,XICV.item_class_code                         --�i�ڋ敪
       ,XICV.item_class_name                         --�i�ڋ敪��
       ,XCCV.crowd_code                              --�Q�R�[�h
       ,XSIR.item_code                               --�i�ڃR�[�h
       ,XIMV.item_name                               --�i�ږ�
       ,XIMV.item_short_name                         --�i�ڗ���
       ,XSIR.lot_no                                  --���b�gNo
       ,ILM.attribute1                               --������
       ,ILM.attribute3                               --�ܖ�����
       ,ILM.attribute2                               --�ŗL�L��
       ,SUM( XSIR.case_amt )        sum_case_amt     --�I���P�[�X�����v
       ,XSIR.content                                 --����
       ,SUM( XSIR.loose_amt )       sum_loose_amt    --�I���o�������v
FROM    xxinv_stc_inventory_result  XSIR             --�I�����ʃA�h�I��
       ,ic_whse_mst                 IWM              --�q�ɖ��擾
       ,xxskz_item_locations_v      XILV             --�ۊǏꏊ�擾�p
       ,xxskz_item_mst2_v           XIMV             --�i�ڎ擾
       ,ic_lots_mst                 ILM              --���b�g���擾
       ,xxskz_prod_class_v          XPCV             --���i�敪�擾
       ,xxskz_item_class_v          XICV             --�i�ڋ敪�擾
       ,xxskz_crowd_code_v          XCCV             --�Q�R�[�h�擾
WHERE
  --�q�ɖ��擾����
       XSIR.invent_whse_code = IWM.whse_code(+)
  --�ۊǏꏊ���擾����
  AND  XILV.allow_pickup_flag(+) = '1'                  --�o�׈����Ώۃt���O
  AND  XSIR.invent_whse_code     = XILV.whse_code(+)
  --�i�ڎ擾����
  AND  XIMV.item_id(+) = XSIR.item_id
  AND  XIMV.start_date_active(+) <= XSIR.invent_date
  AND  XIMV.end_date_active(+)   >= XSIR.invent_date
  --���b�g���擾����
  AND  XSIR.item_id = ILM.item_id(+)
  AND  XSIR.lot_id = ILM.lot_id(+)
  --���i�敪�擾����
  AND  XPCV.item_id(+) = XSIR.item_id
  --�i�ڋ敪�擾����
  AND  XICV.item_id(+) = XSIR.item_id
  --�Q�R�[�h�擾����
  AND  XCCV.item_id(+) = XSIR.item_id
GROUP BY TO_CHAR( XSIR.invent_date, 'YYYYMM' )
        ,XSIR.invent_whse_code
        ,IWM.whse_name
        ,XILV.segment1
        ,XILV.description
        ,XPCV.prod_class_code
        ,XPCV.prod_class_name
        ,XICV.item_class_code
        ,XICV.item_class_name
        ,XCCV.crowd_code
        ,XSIR.item_code
        ,XIMV.item_name
        ,XIMV.item_short_name
        ,XSIR.lot_no
        ,ILM.attribute1
        ,ILM.attribute2
        ,ILM.attribute3
        ,XSIR.content
/
COMMENT ON TABLE APPS.XXSKZ_�I�����ʏW�v_��{_V IS 'XXSKZ_�I�����ʏW�v (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�I���N��         IS '�I���N��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�I���q�ɃR�[�h   IS '�I���q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�I���q�ɖ�       IS '�I���q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�ۊǏꏊ�R�[�h   IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�ۊǏꏊ��       IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.���i�敪         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.���i�敪��       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�i�ڋ敪         IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�i�ڋ敪��       IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�Q�R�[�h         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�i�ڃR�[�h       IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�i�ږ�           IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�i�ڗ���         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.���b�gNO         IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.������           IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�ܖ�����         IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�ŗL�L��         IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�I���P�[�X�����v IS '�I���P�[�X�����v'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.����             IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�����ʏW�v_��{_V.�I���o�������v   IS '�I���o�������v'
/
