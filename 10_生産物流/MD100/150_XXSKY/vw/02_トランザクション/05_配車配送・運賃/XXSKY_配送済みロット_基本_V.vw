CREATE OR REPLACE VIEW APPS.XXSKY_�z���ς݃��b�g_��{_V
(
 �z����R�[�h
,�z���於
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�o�ɓ�
,�ő吻���N����
,�ő�ܖ�����
)
AS
SELECT
        XPS2V.party_site_number                             deliver_to          --�z����R�[�h
       ,XPS2V.party_site_name                               deliver_name        --�z���於
       ,XPCV.prod_class_code                                prod_class_code     --���i�敪
       ,XPCV.prod_class_name                                prod_class_name     --���i�敪��
       ,XICV.item_class_code                                item_class_code     --�i�ڋ敪
       ,XICV.item_class_name                                item_class_name     --�i�ڋ敪��
       ,XCCV.crowd_code                                     crowd_code          --�Q�R�[�h
       ,XIM2V.item_no                                       item_code           --�i�ڃR�[�h
       ,XIM2V.item_name                                     item_name           --�i�ږ�
       ,XIM2V.item_short_name                               item_short_name     --�i�ڗ���
       ,SSHP.shipped_date                                   shipped_date        --�o�ɓ�
       ,SSHP.max_lot_date                                   max_lot_date        --�ő吻���N����
       ,SSHP.max_best_bfr_date                              max_best_bfr_date   --�ő�ܖ�����
  FROM (
          SELECT
                  SHIP.deliver_to_id                        deliver_to_id       --�z����ID
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
                 ,SHIP.deliver_to                           deliver_to          --�z����R�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
                 ,SHIP.item_id                              item_id             --�i��ID
                 ,MAX( SHIP.shipped_date )                  shipped_date        --�o�ɓ�
                 ,MAX( SHIP.lot_date )                      max_lot_date        --�ő吻���N����
                 ,MAX( SHIP.best_bfr_date )                 max_best_bfr_date   --�ő�ܖ�����
            FROM
                 ( --�o�׏�񂩂�Ώۃf�[�^�𒊏o
                   SELECT
                           NVL( XOHA.result_deliver_to_id, XOHA.deliver_to_id )
                                                            deliver_to_id       --�z����ID
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
                          ,NVL( XOHA.result_deliver_to, XOHA.deliver_to )
                                                            deliver_to          --�z����R�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
                          ,XMLD.item_id                     item_id             --�i��ID
                          ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )
                                                            shipped_date        --�o�ɓ�
                          ,TO_DATE( ILM.attribute1 )        lot_date            --�����N����
                          ,TO_DATE( ILM.attribute3 )        best_bfr_date       --�ܖ�����
                     FROM
                           xxwsh_order_headers_all          XOHA                --�󒍃w�b�_�A�h�I��
                          ,oe_transaction_types_all         OTTA                --�󒍃^�C�v�}�X�^
                          ,xxwsh_order_lines_all            XOLA                --�󒍖��׃A�h�I��
                          ,xxinv_mov_lot_details            XMLD                --�ړ����b�g�ڍ׃A�h�I��
                          ,ic_lots_mst                      ILM                 --���b�g���擾�p
                    WHERE
                      --�o�׏�񒊏o����
                           OTTA.attribute1                  = '1'               --�o��
                      AND  OTTA.attribute4                  = '1'               --�ʏ�o��(���{��p���o�ׂ��܂܂Ȃ�)
                      --�󒍃w�b�_�A�h�I���Ƃ̌���
                      AND  XOHA.req_status                  IN ('03', '04')     --'03:���ߍ�'�A'04:���ьv���'
                      AND  XOHA.latest_external_flag        = 'Y'
                      AND  XOHA.deliver_to_id               IS NOT NULL         --�j���̃f�[�^���͏��O
                      AND  XOHA.order_type_id               = OTTA.transaction_type_id
                      --�󒍖��׃A�h�I���Ƃ̌���
                      AND  NVL( XOLA.delete_flag, 'N' )    <> 'Y'               --�������׈ȊO
                      AND  XOHA.order_header_id             = XOLA.order_header_id
                      --�ړ����b�g�ڍ׃A�h�I���Ƃ̌���
                      AND  XMLD.document_type_code          = '10'              --�o�׈˗�
                      AND  XMLD.record_type_code            = DECODE( XOHA.req_status
                                                                    , '04', '20'    --�X�e�[�^�X '04:���ьv���' �̏ꍇ�� '20:����'
                                                                    , '10' )        --                         ��L�ȊO�� '10:�w��'
                      AND  XOLA.order_line_id               = XMLD.mov_line_id
                      --���b�g�}�X�^�Ƃ̌���
                      AND  XMLD.item_id                     = ILM.item_id(+)
                      AND  XMLD.lot_id                      = ILM.lot_id(+)
                 )    SHIP
          GROUP BY
                  SHIP.deliver_to_id                        --�z����ID
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
                 ,SHIP.deliver_to                           --�z����R�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
                 ,SHIP.item_id                              --�i��ID
       )                           SSHP                     --�e�g�����U�N�V�������
       ,xxsky_prod_class_v         XPCV                     --���i�敪�擾�p
       ,xxsky_item_class_v         XICV                     --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v         XCCV                     --�Q�R�[�h�擾�p
       ,xxsky_item_mst2_v          XIM2V                    --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2
       ,xxsky_party_sites2_v       XPS2V                    --SKYLINK�p����VIEW �z������VIEW2
 WHERE
   --�i�ڏ��擾����
        SSHP.item_id               = XIM2V.item_id(+)
   AND  SSHP.shipped_date         >= XIM2V.start_date_active(+)
   AND  SSHP.shipped_date         <= XIM2V.end_date_active(+)
   --���i�E�i�ځE�Q���擾����
   AND  SSHP.item_id               = XPCV.item_id(+)        --���i�敪
   AND  SSHP.item_id               = XICV.item_id(+)        --�i�ڋ敪
   AND  SSHP.item_id               = XCCV.item_id(+)        --�Q�R�[�h
   --�z���於�擾����
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--   AND  SSHP.deliver_to_id         = XPS2V.party_site_id(+)
   AND  SSHP.deliver_to            = XPS2V.party_site_number(+)
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
   AND  SSHP.shipped_date         >= XPS2V.start_date_active(+)
   AND  SSHP.shipped_date         <= XPS2V.end_date_active(+)
/
COMMENT ON TABLE APPS.XXSKY_�z���ς݃��b�g_��{_V IS 'SKYLINK�p�z���ς݃��b�g�}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�z����R�[�h IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�z���於 IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�o�ɓ� IS '�o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�ő吻���N���� IS '�ő吻���N����'
/
COMMENT ON COLUMN APPS.XXSKY_�z���ς݃��b�g_��{_V.�ő�ܖ����� IS '�ő�ܖ�����'
/
