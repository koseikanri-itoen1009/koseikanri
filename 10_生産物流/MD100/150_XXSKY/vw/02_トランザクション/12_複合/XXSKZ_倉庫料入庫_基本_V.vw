/*************************************************************************
 * 
 * View  Name      : XXSKZ_�q�ɗ�����_��{_V
 * Description     : XXSKZ_�q�ɗ�����_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/28    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�q�ɗ�����_��{_V
(
 ���ɐ�ۊǏꏊ
,���ɐ�ۊǏꏊ��
,���ɐ�ۊǏꏊ����
,�o�Ɍ`��
,�o�Ɏ��ѓ�
,���Ɏ��ѓ�
,�o�Ɍ��ۊǏꏊ
,�o�Ɍ��ۊǏꏊ��
,�o�Ɍ��ۊǏꏊ����
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�����
,���ѐ���
,���уP�[�X����
)
AS
SELECT
        MRO.ship_to                ship_to             -- ���ɐ�ۊǏꏊ
       ,ILOC.description           ship_to_name        -- ���ɐ�ۊǏꏊ��
       ,ILOC.short_name            ship_to_s_name      -- ���ɐ�ۊǏꏊ����
       ,MRO.syukoform              syukoform           -- �o�Ɍ`��
       ,MRO.shipped_date           shipped_date        -- �o�Ɏ��ѓ�
       ,MRO.arrival_date           arrival_date        -- ���Ɏ��ѓ�
       ,MRO.ship_from              ship_from           -- �o�Ɍ��ۊǏꏊ
       ,MRO.ship_from_name         ship_from_name      -- �o�Ɍ��ۊǏꏊ��
       ,MRO.ship_from_s_name       ship_from_s_name    -- �o�Ɍ��ۊǏꏊ��
       ,PRODC.prod_class_code      prod_class_code     -- ���i�敪
       ,PRODC.prod_class_name      prod_class_name     -- ���i�敪��
       ,ITEMC.item_class_code      item_class_code     -- �i�ڋ敪
       ,ITEMC.item_class_name      item_class_name     -- �i�ڋ敪��
       ,CROWD.crowd_code           crowd_code          -- �Q�R�[�h
       ,MRO.item_code              item_code           -- �i�ڃR�[�h
       ,ITEM.item_name             item_name           -- �i�ږ�
       ,ITEM.item_short_name       item_s_name         -- �i�ڗ���
       ,NVL( DECODE( MRO.lot_no, 'DEFAULTLOT', '0', MRO.lot_no ), '0' )
                                   lot_no              -- ���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute1    --���b�g�Ǘ��i   �����b�gNO���擾
             ELSE NULL                                    --�񃍃b�g�Ǘ��i ��NULL
        END                        seizou_ymd          -- �����N����
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute2    --���b�g�Ǘ��i   �����b�gNO���擾
             ELSE NULL                                    --�񃍃b�g�Ǘ��i ��NULL
        END                        koyu_kigo           -- �ŗL�L��
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute3    --���b�g�Ǘ��i   �����b�gNO���擾
             ELSE NULL                                    --�񃍃b�g�Ǘ��i ��NULL
        END                        syoumi_ymd          -- �ܖ�����
       ,MRO.quantity               quantity            -- ���ѐ���
       ,TRUNC( MRO.quantity / ITEM.num_of_cases )
                                   quantity            -- ���уP�[�X����
  FROM ( --���Ɏ��уf�[�^���擾
          --=====================================================================
          -- �ړ� ���Ɏ��уf�[�^
          --=====================================================================
          SELECT
                  XMRIH.ship_to_locat_code        ship_to             -- ���ɐ�ۊǏꏊ
                 ,'�ړ�'                          syukoform           -- �o�Ɍ`��
                 ,NVL( XMRIH.actual_ship_date   , XMRIH.schedule_ship_date    )
                                                  shipped_date        -- �o�Ɏ��ѓ�
                 ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                                  arrival_date        -- ���Ɏ��ѓ�
                 ,XMRIH.shipped_locat_code        ship_from           -- �o�Ɍ��ۊǏꏊ
                 ,ILOC.description                ship_from_name      -- �o�Ɍ��ۊǏꏊ��
                 ,ILOC.short_name                 ship_from_s_name    -- �o�Ɍ��ۊǏꏊ����
                 ,XMLD.item_id                    item_id             -- �i�ڃR�[�h
                 ,XMLD.item_code                  item_code           -- �i�ڃR�[�h
                 ,XMLD.lot_id                     lot_id              -- ���b�gID
                 ,XMLD.lot_no                     lot_no              -- ���b�gNo
                 ,XMLD.actual_quantity            quantity            -- ���ѐ���
            FROM
                  xxcmn_mov_req_instr_hdrs_arc     XMRIH              -- �ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                 ,xxcmn_mov_req_instr_lines_arc    XMRIL              -- �ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                 ,xxcmn_mov_lot_details_arc           XMLD            -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                 ,xxskz_item_locations2_v         ILOC                -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�Ɍ��ۊǏꏊ���擾�p)
           WHERE
             -- �ړ� ���ɏ��擾
                  XMRIH.status                    IN ( '05', '06' )   -- '05:���ɕ񍐂���'�A'06:���o�ɕ񍐂���'
             -- �ړ����׏��擾
             AND  NVL( XMRIL.delete_flg, 'N' )   <> 'Y'               -- �������׈ȊO
             AND  XMRIH.mov_hdr_id                = XMRIL.mov_hdr_id
             -- �ړ����b�g�ڍ׏��擾
             AND  XMLD.document_type_code         = '20'              -- �ړ�
             AND  XMLD.record_type_code           = '30'              -- ���Ɏ���
             AND  XMRIL.mov_line_id               = XMLD.mov_line_id
             -- �o�Ɍ��ۊǏꏊ���擾
             AND  XMRIH.shipped_locat_id          = ILOC.inventory_location_id(+)
          --[ �ړ� ���Ɏ��уf�[�^  END ]
         UNION ALL
          --=====================================================================
          -- ������� ���Ɏ��уf�[�^
          --   �ˎ�����f�[�^���O�ׂ̈ɔ������ƌ���
          --=====================================================================
          SELECT
                  XRART.location_code             ship_to             -- ���ɐ�ۊǏꏊ
                 ,FLV01.meaning                   syukoform           -- �o�Ɍ`��
                 ,XRART.txns_date                 shipped_date        -- �o�Ɏ��ѓ�
                 ,XRART.txns_date                 arrival_date        -- ���Ɏ��ѓ�
                 ,XRART.vendor_code               ship_from           -- �o�Ɍ��ۊǏꏊ
                 ,VNDR.vendor_name                ship_from_name      -- �o�Ɍ��ۊǏꏊ��
                 ,VNDR.vendor_short_name          ship_from_s_name    -- �o�Ɍ��ۊǏꏊ����
                 ,XRART.item_id                   item_id             -- �i��ID
                 ,XRART.item_code                 item_code           -- �i�ڃR�[�h
                 ,XRART.lot_id                    lot_id              -- ���b�gID
                 ,XRART.lot_number                lot_no              -- ���b�gNo
                 ,XRART.quantity                  quantity            -- ���ѐ���
            FROM
                  xxpo_rcv_and_rtn_txns           XRART               -- ����ԕi���уA�h�I��
                 ,po_headers_all                  PHA                 -- �����w�b�_
                 ,po_lines_all                    PLA                 -- ��������
                 ,xxskz_vendors2_v                VNDR                -- SKYLINK�p����VIEW �d������VIEW(����於)
                 ,fnd_lookup_values               FLV01               -- �N�C�b�N�R�[�h(���ы敪��)
           WHERE
             --����������������ԕi�f�[�^�̎擾
                  XRART.txns_type                 = '1'               -- '1:�����������'
             --�����f�[�^�Ƃ̌���
             AND  NVL( PLA.cancel_flag, 'N' )    <> 'Y'               -- �L�����Z���ȊO
             AND  NVL( PLA.attribute13, 'N' )     = 'Y'               -- ������
             AND  XRART.source_document_number              = PHA.segment1
             AND  XRART.source_document_line_num            = PLA.line_num
             AND  PHA.po_header_id                          = PLA.po_header_id
             -- ����於���擾
             AND  XRART.vendor_id                 = VNDR.vendor_id(+)
             AND  XRART.txns_date                >= VNDR.start_date_active(+)
             AND  XRART.txns_date                <= VNDR.end_date_active(+)
             --�y�N�C�b�N�R�[�h�z���ы敪��
             AND  FLV01.language(+)               = 'JA'
             AND  FLV01.lookup_type(+)            = 'XXPO_TXNS_TYPE'
             AND  FLV01.lookup_code(+)            = XRART.txns_type
          --[ ������� ���Ɏ��уf�[�^  END ]
         UNION ALL
          --=====================================================================
          -- ��������ԕi�E���������ԕi ���Ɏ��уf�[�^
          --   �˔�������ԕi�Ɏ�����͂��蓾�Ȃ��̂Ŕ����f�[�^�Ƃ̌����͕s�v
          --=====================================================================
          SELECT
                  XRART.location_code             ship_to             -- ���ɐ�ۊǏꏊ
                 ,FLV01.meaning                   syukoform           -- �o�Ɍ`��
                 ,XRART.txns_date                 shipped_date        -- �o�Ɏ��ѓ�
                 ,XRART.txns_date                 arrival_date        -- ���Ɏ��ѓ�
                 ,XRART.vendor_code               ship_from           -- �o�Ɍ��ۊǏꏊ
                 ,VNDR.vendor_name                ship_from_name      -- �o�Ɍ��ۊǏꏊ��
                 ,VNDR.vendor_short_name          ship_from_s_name    -- �o�Ɍ��ۊǏꏊ����
                 ,XRART.item_id                   item_id             -- �i��ID
                 ,XRART.item_code                 item_code           -- �i�ڃR�[�h
                 ,XRART.lot_id                    lot_id              -- ���b�gID
                 ,XRART.lot_number                lot_no              -- ���b�gNo
                 ,XRART.quantity * -1             quantity            -- ���ѐ���(�ԕi�f�[�^�Ȃ̂Ń}�C�i�X�l)
            FROM
                  xxpo_rcv_and_rtn_txns           XRART               -- ����ԕi���уA�h�I��
                 ,xxskz_vendors2_v                VNDR                -- SKYLINK�p����VIEW �d������VIEW(����於)
                 ,fnd_lookup_values               FLV01               -- �N�C�b�N�R�[�h(���ы敪��)
           WHERE
             -- ���������ԕi�f�[�^�擾
                  XRART.txns_type                 IN ( '2', '3' )     -- '2:���������ԕi'�A'3:���������ԕi'
             -- ����於���擾
             AND  XRART.vendor_id                 = VNDR.vendor_id(+)
             AND  XRART.txns_date                >= VNDR.start_date_active(+)
             AND  XRART.txns_date                <= VNDR.end_date_active(+)
             --�y�N�C�b�N�R�[�h�z���ы敪��
             AND  FLV01.language(+)               = 'JA'
             AND  FLV01.lookup_type(+)            = 'XXPO_TXNS_TYPE'
             AND  FLV01.lookup_code(+)            = XRART.txns_type
          --[ ��������ԕi�E���������ԕi ���Ɏ��уf�[�^  END ]
         UNION ALL
          --===============================================
          -- �q�֕ԕi ���Ɏ��уf�[�^
          --===============================================
          SELECT
                  KRHN.ship_to                    ship_to             -- ���ɐ�ۊǏꏊ
                 ,KRHN.syukoform                  syukoform           -- �o�Ɍ`��
                 ,KRHN.shipped_date               shipped_date        -- �o�Ɏ��ѓ�
                 ,KRHN.arrival_date               arrival_date        -- ���Ɏ��ѓ�
                 ,KRHN.ship_from                  ship_from           -- �o�Ɍ��ۊǏꏊ
                 ,PSITE.party_site_name           ship_from_name      -- �o�Ɍ��ۊǏꏊ��
                 ,PSITE.party_site_short_name     ship_from_s_name    -- �o�Ɍ��ۊǏꏊ����
                 ,KRHN.item_id                    item_id             -- �i��ID
                 ,KRHN.item_code                  item_code           -- �i�ڃR�[�h
                 ,KRHN.lot_id                     lot_id              -- ���b�gID
                 ,KRHN.lot_no                     lot_no              -- ���b�gNo
                 ,KRHN.quantity                   quantity            -- ���ѐ���
            FROM (  --�O�������ׂ̈ɕ��₢���킹
                    SELECT
                            XOHA.deliver_from          ship_to        -- ���ɐ�ۊǏꏊ
                           ,OTTT.name                  syukoform      -- �o�Ɍ`��
                           ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date    )
                                                       shipped_date   -- �o�Ɏ��ѓ�
                           ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )
                                                       arrival_date   -- ���Ɏ��ѓ�
                           ,NVL( XOHA.result_deliver_to_id, XOHA.deliver_to_id )
                                                       ship_from_id   -- �o�Ɍ��ۊǏꏊID
                           ,CASE WHEN XOHA.result_deliver_to_id IS NULL THEN XOHA.deliver_to           --�o�א�_����ID�����݂��Ȃ��ꍇ�͏o�א�
                                 ELSE                                        XOHA.result_deliver_to    --�o�א�_����ID�����݂���ꍇ�͏o�א�_����
                            END                        ship_from      -- �o�Ɍ��ۊǏꏊ
                           ,XMLD.item_id               item_id        -- �i��ID
                           ,XMLD.item_code             item_code      -- �i�ڃR�[�h
                           ,XMLD.lot_id                lot_id         -- ���b�gID
                           ,XMLD.lot_no                lot_no         -- ���b�gNO
                           ,XMLD.actual_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 )
                                                       quantity       -- ���ѐ���(����̏ꍇ�̓}�C�i�X�l)
                      FROM
                            xxcmn_order_headers_all_arc    XOHA       -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                           ,xxcmn_order_lines_all_arc      XOLA       -- �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                           ,xxcmn_mov_lot_details_arc      XMLD       -- �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                           ,oe_transaction_types_all   OTTA           -- �󒍃^�C�v�}�X�^
                           ,oe_transaction_types_tl    OTTT           -- �󒍃^�C�v�}�X�^(���{��)
                     WHERE
                       -- �q�֕ԕi�f�[�^�擾
                            OTTA.attribute1            = '3'          -- '3':�q�֕ԕi
                       AND  XOHA.req_status            = '04'         -- '���ьv���'
                       AND  XOHA.latest_external_flag  = 'Y'          -- �ŐV�t���O
                       AND  XOHA.order_type_id         = OTTA.transaction_type_id
                       -- �󒍖��׏��擾
                       AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'       -- �������׈ȊO
                       AND  XOHA.order_header_id       = XOLA.order_header_id
                       -- �ړ����b�g�ڍ׏��擾
                       AND  XMLD.document_type_code    = '10'         -- '10:�o�׈˗�'
                       AND  XMLD.record_type_code      = '20'         -- '20:�o�Ɏ���'
                       AND  XOLA.order_line_id         = XMLD.mov_line_id
                       -- �󒍃^�C�v���擾
                       AND  OTTT.language(+)           = 'JA'
                       AND  XOHA.order_type_id         = OTTT.transaction_type_id(+)
               )                                  KRHN                -- �q�֕ԕi�f�[�^
              ,xxskz_party_sites2_v               PSITE               -- SKYLINK�p����VIEW �z������VIEW2(�o�Ɍ��ۊǏꏊ���擾�p)
          WHERE
            -- �o�Ɍ��ۊǏꏊ���擾
                 KRHN.ship_from_id                = PSITE.party_site_id(+)
            AND  KRHN.arrival_date               >= PSITE.start_date_active(+)
            AND  KRHN.arrival_date               <= PSITE.end_date_active(+)
          --[ �q�֕ԕi ���Ɏ��уf�[�^  END ]
        )                          MRO                 -- �ړ��{����ԕi�{�q�֕ԕi�̓��Ɏ��уf�[�^
        --�ȉ����̎擾�p
       ,xxskz_item_locations_v     ILOC                -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(���ɐ�ۊǏꏊ���擾�p)
       ,xxskz_item_mst2_v          ITEM                -- SKYLINK�p����VIEW OPM�i�ڏ��VIEW
       ,xxskz_prod_class_v         PRODC               -- SKYLINK�p���i�敪�擾VIEW
       ,xxskz_item_class_v         ITEMC               -- SKYLINK�p�i�ڋ敪�擾VIEW
       ,xxskz_crowd_code_v         CROWD               -- SKYLINK�p�S�R�[�h�擾VIEW
       ,ic_lots_mst                LOT                 -- ���b�g�}�X�^
 WHERE
   -- ���ɐ�ۊǏꏊ���擾
        MRO.ship_to                = ILOC.segment1(+)
   -- �i�ڏ��擾
   AND  MRO.item_id                = ITEM.item_id(+)
   AND  MRO.arrival_date          >= ITEM.start_date_active(+)
   AND  MRO.arrival_date          <= ITEM.end_date_active(+)
   -- �i�ڃJ�e�S�����擾
   AND  MRO.item_id                = PRODC.item_id(+)   -- ���i�敪
   AND  MRO.item_id                = ITEMC.item_id(+)   -- �i�ڋ敪
   AND  MRO.item_id                = CROWD.item_id(+)   -- �Q�R�[�h
   -- ���b�g���擾
   AND  MRO.item_id                = LOT.item_id(+)
   AND  MRO.lot_id                 = LOT.lot_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�q�ɗ�����_��{_V IS 'SKYLINK�p�q�ɗ����Ɋ�{VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���ɐ�ۊǏꏊ     IS '���ɐ�ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���ɐ�ۊǏꏊ��   IS '���ɐ�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���ɐ�ۊǏꏊ���� IS '���ɐ�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�o�Ɍ`��           IS '�o�Ɍ`��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�o�Ɏ��ѓ�         IS '�o�Ɏ��ѓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���Ɏ��ѓ�         IS '���Ɏ��ѓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�o�Ɍ��ۊǏꏊ     IS '�o�Ɍ��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�o�Ɍ��ۊǏꏊ��   IS '�o�Ɍ��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�o�Ɍ��ۊǏꏊ���� IS '�o�Ɍ��ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�i�ڋ敪           IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�i�ڋ敪��         IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�Q�R�[�h           IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�i�ڃR�[�h         IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�i�ږ�             IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�i�ڗ���           IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���b�gNO           IS '���b�gNO'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�����N����         IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�ŗL�L��           IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.�ܖ�����           IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���ѐ���           IS '���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�q�ɗ�����_��{_V.���уP�[�X����     IS '���уP�[�X����'
/
