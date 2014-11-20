/*************************************************************************
 * 
 * View  Name      : XXSKZ_�����������_��{_V
 * Description     : XXSKZ_�����������_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/21    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�����������_��{_V
(
 �����ԍ�
,����ԕi�ԍ�
,���הԍ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�P��
,����
,���b�g�ԍ�
,�����N����
,�ŗL�L��
,�ܖ�����
,�H��R�[�h
,�H�ꖼ
,�t�уR�[�h
,�݌ɓ���
,�˗�����
,�˗����ʒP�ʃR�[�h
,�d����o�ד�
,�d����o�א���
,�������
,�d���艿
,���t�w��
,�����P��
,��������
,�����݌ɓ��ɐ�
,�����݌ɓ��ɐ於
,���ʊm��t���O
,���ʊm��t���O��
,���z�m��t���O
,���z�m��t���O��
,����t���O
,����t���O��
,�E�v
,����_�쐬��
,����_�쐬��
,����_�ŏI�X�V��
,����_�ŏI�X�V��
,����_�ŏI�X�V���O�C��
,������ѓ�
,����P��
,����ԕi����
,����ԕi�P��
,����ԕi���Z����
,������
,������P��
,���K�敪
,���K�敪��
,���K
,�a����K���z
,���ۋ��敪
,���ۋ��敪��
,���ۋ�
,���ۋ��z
,��������z
,���_�쐬��
,���_�쐬��
,���_�ŏI�X�V��
,���_�ŏI�X�V��
,���_�ŏI�X�V���O�C��
)
AS
SELECT
        POL.po_number                                       po_number                     --�����ԍ�
       ,POL.rcv_rtn_number                                  rcv_rtn_number                --����ԕi�ԍ��iNULL�ł����������Ƃ��Ďg�p����� 'Dummy' �ŕ\���j
       ,POL.line_num                                        line_num                      --���הԍ�
       ,PRODC.prod_class_code                               prod_class_code               --���i�敪
       ,PRODC.prod_class_name                               prod_class_name               --���i�敪��
       ,ITEMC.item_class_code                               item_class_code               --�i�ڋ敪
       ,ITEMC.item_class_name                               item_class_name               --�i�ڋ敪��
       ,CROWD.crowd_code                                    crowd_code                    --�Q�R�[�h
       ,ITEM.item_no                                        item_code                     --�i�ڃR�[�h
       ,ITEM.item_name                                      item_name                     --�i�ږ�
       ,ITEM.item_short_name                                item_short_name               --�i�ڗ���
       ,NVL( POL.unit_price, 0 )                            unit_price                    --�P��
       ,NVL( POL.quantity, 0 )                              quantity                      --����
       ,NVL( DECODE( POL.lot_no, 'DEFAULTLOT', '0', POL.lot_no ), '0' )
                                                            lot_no                        --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute1  --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                  --�񃍃b�g�Ǘ��i ��NULL
        END                                                 manufacture_date              --�����N����
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute2  --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                  --�񃍃b�g�Ǘ��i ��NULL
        END                                                 uniqe_sign                    --�ŗL�L��
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute3  --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                  --�񃍃b�g�Ǘ��i ��NULL
        END                                                 expiration_date               --�ܖ�����
       ,POL.factory_code                                    factory_code                  --�H��R�[�h
       ,VDST.vendor_site_name                               factory_name                  --�H�ꖼ
       ,POL.futai_code                                      futai_code                    --�t�уR�[�h
       ,NVL( POL.pack_qty, 0 )                              pack_qty                      --�݌ɓ���
       ,NVL( POL.request_qty, 0 )                           request_qty                   --�˗�����
       ,POL.request_uom                                     request_uom                   --�˗����ʒP�ʃR�[�h
       ,POL.vendor_dlvr_date                                vendor_dlvr_date              --�d����o�ד�
       ,NVL( POL.vendor_dlvr_qty, 0 )                       vendor_dlvr_qty               --�d����o�א���
       ,NVL( POL.rcv_qty, 0 )                               rcv_qty                       --�������
       ,NVL( POL.purchase_amt, 0 )                          purchase_amt                  --�d���艿
       ,POL.date_reserved                                   date_reserved                 --���t�w��
       ,POL.order_uom                                       order_uom                     --�����P��
       ,NVL( POL.order_qty, 0 )                             order_qty                     --��������
       ,POL.party_dlvr_to                                   party_dlvr_to                 --�����݌ɓ��ɐ�
       ,ILOC.description                                    party_dlvr_to_name            --�����݌ɓ��ɐ於
       ,POL.fix_qty_flg                                     fix_qty_flg                   --���ʊm��t���O
       ,FLV01.meaning                                       fix_qty_flg_name              --���ʊm��t���O��
       ,POL.fix_amt_flg                                     fix_amt_flg                   --���z�m��t���O
       ,FLV02.meaning                                       fix_amt_flg_name              --���z�m��t���O��
       ,NVL( POL.cancel_flg, 'N' )                          cancel_flg                    --����t���O
       ,FLV03.meaning                                       cancel_flg_name               --����t���O��
       ,POL.description                                     description                   --�E�v
       ,FU_CB_H.user_name                                   h_created_by                  --����_�쐬��
       ,TO_CHAR( POL.h_creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_creation_date               --����_�쐬��
       ,FU_LU_H.user_name                                   h_last_updated_by             --����_�ŏI�X�V��
       ,TO_CHAR( POL.h_last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_last_update_date            --����_�ŏI�X�V��
       ,FU_LL_H.user_name                                   h_last_update_login           --����_�ŏI�X�V���O�C��
       ,POL.u_txns_date                                     u_txns_date                   --������ѓ�
       ,POL.u_uom                                           u_uom                         --����P��
       ,NVL( POL.u_rcv_rtn_quantity, 0 )                    u_rcv_rtn_quantity            --����ԕi����
       ,POL.u_rcv_rtn_uom                                   u_rcv_rtn_uom                 --����ԕi�P��
       ,NVL( POL.u_conversion_factor, 0 )                   u_conversion_factor           --����ԕi���Z����
       ,NVL( POL.kobiki_rate, 0 )                           kobiki_rate                   --������
       ,NVL( POL.kobki_converted_unit_price, 0 )            kobki_converted_unit_price    --������P��
       ,POL.kousen_type                                     kousen_type                   --���K�敪
       ,FLV04.meaning                                       kousen_type_name              --���K�敪��
       ,NVL( POL.kousen_rate_or_unit_price, 0 )             kousen_rate_or_unit_price     --���K
       ,NVL( POL.kousen_price, 0 )                          kousen_price                  --�a����K���z
       ,POL.fukakin_type                                    fukakin_type                  --���ۋ��敪
       ,FLV05.meaning                                       fukakin_type_name             --���ۋ��敪��
       ,NVL( POL.fukakin_rate_or_unit_price, 0 )            fukakin_rate_or_unit_price    --���ۋ�
       ,NVL( POL.fukakin_price, 0 )                         fukakin_price                 --���ۋ��z
       ,NVL( POL.kobki_converted_price, 0 )                 kobki_converted_price         --��������z�i������P���~������ʁj
       ,FU_CB_U.user_name                                   u_created_by                  --���_�쐬��
       ,TO_CHAR( POL.u_creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            u_creation_date               --���_�쐬��
       ,FU_LU_U.user_name                                   u_last_updated_by             --���_�ŏI�X�V��
       ,TO_CHAR( POL.u_last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            u_last_update_date            --���_�ŏI�X�V��
       ,FU_LL_U.user_name                                   u_last_update_login           --���_�ŏI�X�V���O�C��
  FROM
       ( --�y�����˗��z�y��������z�y��������ԕi�z�y���������ԕi�z �̊e�f�[�^���擾
          --========================================================================
          -- �����˗��f�[�^ �i�����˗��f�[�^ NOT EXISTS �����f�[�^�j
          --========================================================================
          SELECT
                  XRH.po_header_number                      po_number                     --�����ԍ�
                 ,'Dummy'                                   rcv_rtn_number                --����ԕi�ԍ��i������уf�[�^�����݂��Ȃ��ׂ� 'Dummy' �Œ�j
                 ,XRL.requisition_line_number               line_num                      --���הԍ�
                 ,XRL.item_id                               item_id                       --�i��ID(OPM�i��ID)
                 ,0                                         unit_price                    --�P��
                 ,0                                         quantity                      --����
                 ,NULL                                      lot_no                        --���b�g�ԍ�
                 ,NULL                                      factory_code                  --�H��R�[�h
                 ,NULL                                      futai_code                    --�t�уR�[�h
                 ,XRL.pack_quantity                         pack_qty                      --�݌ɓ���
                 ,XRL.requested_quantity                    request_qty                   --�˗�����
                 ,XRL.requested_quantity_uom                request_uom                   --�˗����ʒP�ʃR�[�h
                 ,NULL                                      vendor_dlvr_date              --�d����o�ד�
                 ,0                                         vendor_dlvr_qty               --�d����o�א���
                 ,0                                         rcv_qty                       --�������
                 ,0                                         purchase_amt                  --�d���艿
                 ,XRL.requested_date                        date_reserved                 --���t�w��
                 ,NULL                                      order_uom                     --�����P��
                 ,XRL.ordered_quantity                      order_qty                     --��������
                 ,NULL                                      party_dlvr_to                 --�����݌ɓ��ɐ�
                 ,NULL                                      fix_qty_flg                   --���ʊm��t���O
                 ,NULL                                      fix_amt_flg                   --���z�m��t���O
                 ,'N'                                       cancel_flg                    --����t���O
                 ,XRL.description                           description                   --�E�v
                 ,XRL.created_by                            h_created_by                  --����_�쐬��
                 ,XRL.creation_date                         h_creation_date               --����_�쐬��
                 ,XRL.last_updated_by                       h_last_updated_by             --����_�ŏI�X�V��
                 ,XRL.last_update_date                      h_last_update_date            --����_�ŏI�X�V��
                 ,XRL.last_update_login                     h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,NULL                                      u_txns_date                   --������ѓ�
                 ,NULL                                      u_uom                         --����P��
                 ,0                                         u_rcv_rtn_quantity            --����ԕi����
                 ,NULL                                      u_rcv_rtn_uom                 --����ԕi�P��
                 ,0                                         u_conversion_factor           --����ԕi���Z����
                 ,0                                         kobiki_rate                   --������
                 ,0                                         kobki_converted_unit_price    --������P��
                 ,NULL                                      kousen_type                   --���K�敪
                 ,0                                         kousen_rate_or_unit_price     --���K
                 ,0                                         kousen_price                  --�a����K���z
                 ,NULL                                      fukakin_type                  --���ۋ��敪
                 ,0                                         fukakin_rate_or_unit_price    --���ۋ�
                 ,0                                         fukakin_price                 --���ۋ��z
                 ,0                                         kobki_converted_price         --��������z�i������P���~������ʁj
                 ,NULL                                      u_created_by                  --���_�쐬��
                 ,NULL                                      u_creation_date               --���_�쐬��
                 ,NULL                                      u_last_updated_by             --���_�ŏI�X�V��
                 ,NULL                                      u_last_update_date            --���_�ŏI�X�V��
                 ,NULL                                      u_last_update_login           --���_�ŏI�X�V���O�C��
                  --���̎擾�p���
                 ,XRH.promised_date                         deliver_date                  --�[����
            FROM
                  xxpo_requisition_headers                  XRH                           --�����˗��w�b�_�A�h�I��
                 ,xxpo_requisition_lines                    XRL                           --�����˗����׃A�h�I��
           WHERE
             --�����˗��w�b�_�Ƃ̌���
                  XRH.requisition_header_id                 = XRL.requisition_header_id
             --�����σf�[�^�́w���������f�[�^�x�Ƃ��ĕ\������ׁA���O����
             AND  NOT EXISTS
                  (
                    SELECT  E_XRL.requisition_line_id
                      FROM  xxpo_requisition_headers        E_XRH
                           ,po_headers_all                  E_PHA
                           ,xxpo_requisition_lines          E_XRL
                           ,po_lines_all                    E_PLA
                     WHERE  E_XRH.po_header_number          = E_PHA.segment1
                       AND  E_XRH.requisition_header_id     = E_XRL.requisition_header_id
                       AND  E_PHA.po_header_id              = E_PLA.po_header_id
                       AND  E_XRL.requisition_line_id       = XRL.requisition_line_id
                  )
          --[ �����˗��f�[�^  END ]
        UNION ALL
-- 2010/07/16 T.Yoshimoto Del Start E_�{�ғ�_03772
--          --========================================================================
--          -- �����E����f�[�^ �i������ы敪 = '1'�j
--          --========================================================================
--          SELECT
--                  PO.po_number                              po_number                     --�����ԍ�
--                 ,NVL( XRART.rcv_rtn_number, 'Dummy' )      rcv_rtn_number                --����ԕi�ԍ��i������уf�[�^�����݂��Ȃ��ꍇ�� 'Dummy' �Œ�j
--                 ,PO.line_num                               line_num                      --���הԍ�
--                 ,PO.item_id                                item_id                       --�i��ID(OPM�i��ID)
--                 ,PO.unit_price                             unit_price                    --�P��
--                 ,PO.quantity                               quantity                      --����
--                 ,PO.lot_no                                 lot_no                        --���b�g�ԍ�
--                 ,PO.factory_code                           factory_code                  --�H��R�[�h
--                 ,PO.futai_code                             futai_code                    --�t�уR�[�h
--                 ,PO.pack_qty                               pack_qty                      --�݌ɓ���
--                 ,0                                         request_qty                   --�˗�����
--                 ,NULL                                      request_uom                   --�˗����ʒP�ʃR�[�h
--                 ,PO.vendor_dlvr_date                       vendor_dlvr_date              --�d����o�ד�
--                 ,PO.vendor_dlvr_qty                        vendor_dlvr_qty               --�d����o�א���
--                 ,PO.rcv_qty                                rcv_qty                       --�������
--                 ,PO.purchase_amt                           purchase_amt                  --�d���艿
--                 ,PO.date_reserved                          date_reserved                 --���t�w��
--                 ,PO.order_uom                              order_uom                     --�����P��
--                 ,PO.order_qty                              order_qty                     --��������
--                 ,PO.party_dlvr_to                          party_dlvr_to                 --�����݌ɓ��ɐ�
--                 ,PO.fix_qty_flg                            fix_qty_flg                   --���ʊm��t���O
--                 ,PO.fix_amt_flg                            fix_amt_flg                   --���z�m��t���O
--                 ,PO.cancel_flg                             cancel_flg                    --����t���O
--                 ,PO.description                            description                   --�E�v
--                 ,PO.h_created_by                           h_created_by                  --����_�쐬��
--                 ,PO.h_creation_date                        h_creation_date               --����_�쐬��
--                 ,PO.h_last_updated_by                      h_last_updated_by             --����_�ŏI�X�V��
--                 ,PO.h_last_update_date                     h_last_update_date            --����_�ŏI�X�V��
--                 ,PO.h_last_update_login                    h_last_update_login           --����_�ŏI�X�V���O�C��
--                 ,XRART.txns_date                           u_txns_date                   --������ѓ�
--                 ,XRART.uom                                 u_uom                         --����P��
--                 ,XRART.rcv_rtn_quantity                    u_rcv_rtn_quantity            --����ԕi����
--                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --����ԕi�P��
--                 ,XRART.conversion_factor                   u_conversion_factor           --����ԕi���Z����
--                 ,TO_NUMBER( PLLA.attribute1 )              kobiki_rate                   --������
--                 ,TO_NUMBER( PLLA.attribute2 )              kobki_converted_unit_price    --������P��
--                 ,PLLA.attribute3                           kousen_type                   --���K�敪
--                 ,TO_NUMBER( PLLA.attribute4 )              kousen_rate_or_unit_price     --���K
--                 ,TO_NUMBER( PLLA.attribute5 )              kousen_price                  --�a����K���z
--                 ,PLLA.attribute6                           fukakin_type                  --���ۋ��敪
--                 ,TO_NUMBER( PLLA.attribute7 )              fukakin_rate_or_unit_price    --���ۋ�
--                 ,TO_NUMBER( PLLA.attribute8 )              fukakin_price                 --���ۋ��z
---- 2009-03-10 H.Iida MOD START �{�ԏ�Q#1131
----                 ,NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( PO.rcv_qty, 0 )
----                                                            kobki_converted_price         --��������z�i������P���~������ʁj
---- 2009-12-28 Y.Fukami MOD START �{�ғ���Q#696
----                 ,NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( XRART.quantity, 0 )
--                 ,ROUND(NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( XRART.quantity, 0 ))
---- 2009-12-28 Y.Fukami MOD END
--                                                            kobki_converted_price         --��������z�i������P���~����ԕi����(�A�h�I��).���ʁj
---- 2009-03-10 H.Iida MOD END
--                 ,XRART.created_by                          u_created_by                  --���_�쐬��
--                 ,XRART.creation_date                       u_creation_date               --���_�쐬��
--                 ,XRART.last_updated_by                     u_last_updated_by             --���_�ŏI�X�V��
--                 ,XRART.last_update_date                    u_last_update_date            --���_�ŏI�X�V��
--                 ,XRART.last_update_login                   u_last_update_login           --���_�ŏI�X�V���O�C��
--                 --���̎擾�p���
--                 ,PO.deliver_date                           deliver_date                  --�[����
--            FROM
--                 (
--                    --����ԕi�A�h�I���ƊO���������s���ׁA���₢���킹�Ƃ���
--                    SELECT
--                            PHA.po_header_id                po_header_id                  --�����w�b�_ID
--                           ,PLA.po_line_id                  po_line_id                    --��������ID
--                           ,PHA.segment1                    po_number                     --�����ԍ�
--                           ,PLA.line_num                    line_num                      --���הԍ�
--                           ,IIMB.item_id                    item_id                       --�i��ID(OPM�i��ID)
--                           ,PLA.unit_price                  unit_price                    --�P��
--                           ,PLA.quantity                    quantity                      --����
--                           ,PLA.attribute1                  lot_no                        --���b�g�ԍ�
--                           ,PLA.attribute2                  factory_code                  --�H��R�[�h
--                           ,PLA.attribute3                  futai_code                    --�t�уR�[�h
--                           ,TO_NUMBER( PLA.attribute4  )    pack_qty                      --�݌ɓ���
--                           ,TO_DATE( PLA.attribute5 )       vendor_dlvr_date              --�d����o�ד�
--                           ,TO_NUMBER( PLA.attribute6  )    vendor_dlvr_qty               --�d����o�א���
--                           ,TO_NUMBER( PLA.attribute7  )    rcv_qty                       --�������
--                           ,TO_NUMBER( PLA.attribute8  )    purchase_amt                  --�d���艿
--                           ,TO_DATE( PLA.attribute9 )       date_reserved                 --���t�w��
--                           ,PLA.attribute10                 order_uom                     --�����P��
--                           ,TO_NUMBER( PLA.attribute11 )    order_qty                     --��������
--                           ,PLA.attribute12                 party_dlvr_to                 --�����݌ɓ��ɐ�
--                           ,PLA.attribute13                 fix_qty_flg                   --���ʊm��t���O
--                           ,PLA.attribute14                 fix_amt_flg                   --���z�m��t���O
--                           ,PLA.cancel_flag                 cancel_flg                    --����t���O
--                           ,PLA.attribute15                 description                   --�E�v
--                           ,PLA.created_by                  h_created_by                  --����_�쐬��
--                           ,PLA.creation_date               h_creation_date               --����_�쐬��
--                           ,PLA.last_updated_by             h_last_updated_by             --����_�ŏI�X�V��
--                           ,PLA.last_update_date            h_last_update_date            --����_�ŏI�X�V��
--                           ,PLA.last_update_login           h_last_update_login           --����_�ŏI�X�V���O�C��
--                            --���̎擾�p���
--                           ,TO_DATE( PHA.attribute4 )       deliver_date                  --�[����
--                      FROM
--                            po_headers_all                  PHA                           --�����w�b�_
--                           ,po_lines_all                    PLA                           --��������
--                           ,mtl_system_items_b              MSIB                          --INV�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
--                           ,ic_item_mst_b                   IIMB                          --OPM�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
--                     WHERE
--                       --�����w�b�_�Ƃ̌���
--                            PHA.po_header_id                = PLA.po_header_id
--                       --INV�i��ID��OPM�i��ID �ϊ�
--                       AND  PLA.item_id                     = MSIB.inventory_item_id
--                       AND  MSIB.organization_id            = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
--                       AND  MSIB.segment1                   = IIMB.item_no
--                 )                                          PO                            --�����f�[�^
--                 ,po_line_locations_all                     PLLA                          --�����[������
--                 ,xxpo_rcv_and_rtn_txns                     XRART                         --����ԕi����(�A�h�I��)
--           WHERE
--             --�����[�����ׂƂ̌����i�y�������z�ȉ��̍��ڂ͎���ԕi���т̃f�[�^�ł͂Ȃ���������g�p����j
--                  PO.po_header_id                           = PLLA.po_header_id
--             AND  PO.po_line_id                             = PLLA.po_line_id
--             --����ԕi���уA�h�I��   �˔����~�܂�i������уf�[�^�����j�̃f�[�^���擾����ׁA�O������
--             AND  XRART.txns_type(+)                        = '1'                         -- ���ы敪:'1:���'
--             AND  PO.po_number                              = XRART.rcv_rtn_number(+)
--             AND  PO.line_num                               = XRART.source_document_line_num(+)
--          --[ �����˗��f�[�^  END ]
-- 2010/07/16 T.Yoshimoto Del End E_�{�ғ�_03772
-- 2010/07/16 T.Yoshimoto Add Start E_�{�ғ�_03772
          --========================================================================
          -- �����E������тȂ��f�[�^(���ʊm��t���O = 'N')
          --========================================================================
          SELECT
                  PHA.segment1                              po_number                     --�����ԍ�
                 ,'Dummy'                                   rcv_rtn_number                --����ԕi�ԍ��i������уf�[�^�����݂��Ȃ��ꍇ�� 'Dummy' �Œ�j
                 ,PLA.line_num                              line_num                      --���הԍ�
                 ,IIMB.item_id                              item_id                       --�i��ID(OPM�i��ID)
                 ,PLA.unit_price                            unit_price                    --�P��
                 ,PLA.quantity                              quantity                      --����
                 ,PLA.attribute1                            lot_no                        --���b�g�ԍ�
                 ,PLA.attribute2                            factory_code                  --�H��R�[�h
                 ,PLA.attribute3                            futai_code                    --�t�уR�[�h
                 ,TO_NUMBER( PLA.attribute4  )              pack_qty                      --�݌ɓ���
                 ,0                                         request_qty                   --�˗�����
                 ,NULL                                      request_uom                   --�˗����ʒP�ʃR�[�h
                 ,TO_DATE( PLA.attribute5 )                 vendor_dlvr_date              --�d����o�ד�
                 ,TO_NUMBER( PLA.attribute6  )              vendor_dlvr_qty               --�d����o�א���
                 ,TO_NUMBER( PLA.attribute7  )              rcv_qty                       --�������
                 ,TO_NUMBER( PLA.attribute8  )              purchase_amt                  --�d���艿
                 ,TO_DATE( PLA.attribute9 )                 date_reserved                 --���t�w��
                 ,PLA.attribute10                           order_uom                     --�����P��
                 ,TO_NUMBER( PLA.attribute11 )              order_qty                     --��������
                 ,PLA.attribute12                           party_dlvr_to                 --�����݌ɓ��ɐ�
                 ,PLA.attribute13                           fix_qty_flg                   --���ʊm��t���O
                 ,PLA.attribute14                           fix_amt_flg                   --���z�m��t���O
                 ,PLA.cancel_flag                           cancel_flg                    --����t���O
                 ,PLA.attribute15                           description                   --�E�v
                 ,PLA.created_by                            h_created_by                  --����_�쐬��
                 ,PLA.creation_date                         h_creation_date               --����_�쐬��
                 ,PLA.last_updated_by                       h_last_updated_by             --����_�ŏI�X�V��
                 ,PLA.last_update_date                      h_last_update_date            --����_�ŏI�X�V��
                 ,PLA.last_update_login                     h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,NULL                                      u_txns_date                   --������ѓ�
                 ,NULL                                      u_uom                         --����P��
                 ,0                                         u_rcv_rtn_quantity            --����ԕi����
                 ,NULL                                      u_rcv_rtn_uom                 --����ԕi�P��
                 ,NULL                                      u_conversion_factor           --����ԕi���Z����
                 ,TO_NUMBER( PLLA.attribute1 )              kobiki_rate                   --������
                 ,TO_NUMBER( PLLA.attribute2 )              kobki_converted_unit_price    --������P��
                 ,PLLA.attribute3                           kousen_type                   --���K�敪
                 ,TO_NUMBER( PLLA.attribute4 )              kousen_rate_or_unit_price     --���K
                 ,TO_NUMBER( PLLA.attribute5 )              kousen_price                  --�a����K���z
                 ,PLLA.attribute6                           fukakin_type                  --���ۋ��敪
                 ,TO_NUMBER( PLLA.attribute7 )              fukakin_rate_or_unit_price    --���ۋ�
                 ,TO_NUMBER( PLLA.attribute8 )              fukakin_price                 --���ۋ��z
                 ,0                                         kobki_converted_price         --��������z�i������P���~����ԕi����(�A�h�I��).���ʁj
                 ,NULL                                      u_created_by                  --���_�쐬��
                 ,NULL                                      u_creation_date               --���_�쐬��
                 ,NULL                                      u_last_updated_by             --���_�ŏI�X�V��
                 ,NULL                                      u_last_update_date            --���_�ŏI�X�V��
                 ,NULL                                      u_last_update_login           --���_�ŏI�X�V���O�C��
                 --���̎擾�p���
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --�[����
            FROM
                  po_headers_all                            PHA                           --�����w�b�_
                 ,po_lines_all                              PLA                           --��������
                 ,mtl_system_items_b                        MSIB                          --INV�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,ic_item_mst_b                             IIMB                          --OPM�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,po_line_locations_all                     PLLA                          --�����[������
           WHERE
             --�����w�b�_�Ƃ̌���
                  PHA.po_header_id                = PLA.po_header_id
             AND  PHA.attribute1                  IN ('15','20','25','99')
             AND  PLA.attribute13                 = 'N'
             --INV�i��ID��OPM�i��ID �ϊ�
             AND  PLA.item_id                     = MSIB.inventory_item_id
             AND  MSIB.organization_id            = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MSIB.segment1                   = IIMB.item_no
             --�����[�����ׂƂ̌����i�y�������z�ȉ��̍��ڂ͎���ԕi���т̃f�[�^�ł͂Ȃ���������g�p����j
             AND  PHA.po_header_id                = PLLA.po_header_id
             AND  PLA.po_line_id                  = PLLA.po_line_id
          --[ �����E������тȂ��f�[�^  END ]
        UNION ALL
          --========================================================================
          -- ������уf�[�^ �i������ы敪 = '1'�j(���ʊm��t���O = 'Y')
          --========================================================================
          SELECT
                  PHA.segment1                              po_number                     --�����ԍ�
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --����ԕi�ԍ�
                 ,PLA.line_num                              line_num                      --���הԍ�
                 ,IIMB.item_id                              item_id                       --�i��ID(OPM�i��ID)
                 ,PLA.unit_price                            unit_price                    --�P��
                 ,PLA.quantity                              quantity                      --����
                 ,PLA.attribute1                            lot_no                        --���b�g�ԍ�
                 ,PLA.attribute2                            factory_code                  --�H��R�[�h
                 ,PLA.attribute3                            futai_code                    --�t�уR�[�h
                 ,TO_NUMBER( PLA.attribute4  )              pack_qty                      --�݌ɓ���
                 ,0                                         request_qty                   --�˗�����
                 ,NULL                                      request_uom                   --�˗����ʒP�ʃR�[�h
                 ,TO_DATE( PLA.attribute5 )                 vendor_dlvr_date              --�d����o�ד�
                 ,TO_NUMBER( PLA.attribute6  )              vendor_dlvr_qty               --�d����o�א���
                 ,TO_NUMBER( PLA.attribute7  )              rcv_qty                       --�������
                 ,TO_NUMBER( PLA.attribute8  )              purchase_amt                  --�d���艿
                 ,TO_DATE( PLA.attribute9 )                 date_reserved                 --���t�w��
                 ,PLA.attribute10                           order_uom                     --�����P��
                 ,TO_NUMBER( PLA.attribute11 )              order_qty                     --��������
                 ,PLA.attribute12                           party_dlvr_to                 --�����݌ɓ��ɐ�
                 ,PLA.attribute13                           fix_qty_flg                   --���ʊm��t���O
                 ,PLA.attribute14                           fix_amt_flg                   --���z�m��t���O
                 ,PLA.cancel_flag                           cancel_flg                    --����t���O
                 ,PLA.attribute15                           description                   --�E�v
                 ,PLA.created_by                            h_created_by                  --����_�쐬��
                 ,PLA.creation_date                         h_creation_date               --����_�쐬��
                 ,PLA.last_updated_by                       h_last_updated_by             --����_�ŏI�X�V��
                 ,PLA.last_update_date                      h_last_update_date            --����_�ŏI�X�V��
                 ,PLA.last_update_login                     h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,XRART.txns_date                           u_txns_date                   --������ѓ�
                 ,XRART.uom                                 u_uom                         --����P��
                 ,XRART.rcv_rtn_quantity                    u_rcv_rtn_quantity            --����ԕi����
                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --����ԕi�P��
                 ,XRART.conversion_factor                   u_conversion_factor           --����ԕi���Z����
                 ,TO_NUMBER( PLLA.attribute1 )              kobiki_rate                   --������
                 ,TO_NUMBER( PLLA.attribute2 )              kobki_converted_unit_price    --������P��
                 ,PLLA.attribute3                           kousen_type                   --���K�敪
                 ,TO_NUMBER( PLLA.attribute4 )              kousen_rate_or_unit_price     --���K
                 -- ���K���z
                 ,CASE
                    -- ���K�敪���u���v�̏ꍇ
                    WHEN PLLA.attribute3 = '2' THEN
                      -- �a������K���z���P��*����*���K/100
                      TRUNC(TO_NUMBER( PLA.attribute8  ) * 
                                       NVL(XRART.quantity, 0) * NVL(TO_NUMBER( PLLA.attribute4 ), 0) / 100 )
                    -- ���K�敪���u�~�v�̏ꍇ
                    WHEN PLLA.attribute3 = '1' THEN
                      -- �a����K���z�����K*����
                      TRUNC( NVL(TO_NUMBER( PLLA.attribute4 ), 0) * NVL(XRART.quantity, 0))
                    -- ���K�敪���u���v�̏ꍇ
                    ELSE
                      0
                  END                                       kousen_price                  --�a����K���z
                 ,PLLA.attribute6                           fukakin_type                  --���ۋ��敪
                 ,TO_NUMBER( PLLA.attribute7 )              fukakin_rate_or_unit_price    --���ۋ�
                 -- ���ۋ��z
                 ,CASE
                    -- ���ۋ��敪���u���v�̏ꍇ
                    WHEN PLLA.attribute6 = '2' THEN
                      -- �����z���P�� * ���� * ������ / 100
                      -- ���ۋ��z���i�P�� * ���� - �����z�j* ���ۗ� / 100
                      TRUNC(
                        ( TO_NUMBER( PLA.attribute8  ) * NVL(XRART.quantity, 0) - 
                          ( TO_NUMBER( PLA.attribute8  ) * NVL(XRART.quantity, 0) * 
                            NVL(TO_NUMBER( PLLA.attribute1 ),0) / 100)) * TO_NUMBER( PLLA.attribute7 ) / 100)
                    -- ���ۋ��敪���u�~�v�̏ꍇ
                    WHEN PLLA.attribute6 = '1' THEN
                      -- ���ۋ��z�����ۋ�*����
                      TRUNC( NVL(TO_NUMBER( PLLA.attribute7 ),0) * NVL(XRART.quantity, 0) )
                    -- ���ۋ��敪���u���v�̏ꍇ
                    ELSE
                      0
                  END                                       fukakin_price                 --���ۋ��z
                 ,ROUND(NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( XRART.quantity, 0 ))
                                                            kobki_converted_price         --��������z�i������P���~����ԕi����(�A�h�I��).���ʁj
                 ,XRART.created_by                          u_created_by                  --���_�쐬��
                 ,XRART.creation_date                       u_creation_date               --���_�쐬��
                 ,XRART.last_updated_by                     u_last_updated_by             --���_�ŏI�X�V��
                 ,XRART.last_update_date                    u_last_update_date            --���_�ŏI�X�V��
                 ,XRART.last_update_login                   u_last_update_login           --���_�ŏI�X�V���O�C��
                 --���̎擾�p���
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --�[����
            FROM
                  po_headers_all                            PHA                           --�����w�b�_
                 ,po_lines_all                              PLA                           --��������
                 ,mtl_system_items_b                        MSIB                          --INV�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,ic_item_mst_b                             IIMB                          --OPM�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,po_line_locations_all                     PLLA                          --�����[������
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --����ԕi����(�A�h�I��)
           WHERE
             --�����w�b�_�Ƃ̌���
                  PHA.po_header_id                = PLA.po_header_id
             AND  PHA.attribute1                  IN ('25','30','35')
             AND  PLA.attribute13                 = 'Y'
             --INV�i��ID��OPM�i��ID �ϊ�
             AND  PLA.item_id                     = MSIB.inventory_item_id
             AND  MSIB.organization_id            = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MSIB.segment1                   = IIMB.item_no
             --�����[�����ׂƂ̌����i�y�������z�ȉ��̍��ڂ͎���ԕi���т̃f�[�^�ł͂Ȃ���������g�p����j
             AND  PHA.po_header_id                = PLLA.po_header_id
             AND  PLA.po_line_id                  = PLLA.po_line_id
             --����ԕi���уA�h�I��
             AND  XRART.txns_type                 = '1'                         -- ���ы敪:'1:���'
             AND  PHA.segment1                    = XRART.rcv_rtn_number
             AND  PLA.line_num                    = XRART.source_document_line_num
          --[ ������уf�[�^  END ]
-- 2010/07/16 T.Yoshimoto Add End E_�{�ғ�_03772
        UNION ALL
          --========================================================================
          -- ��������ԕi�f�[�^ �i������ы敪 = '2'�j
          --   �����ʁA���z�̓}�C�i�X�l�Ƃ���
          --========================================================================
          SELECT
                  PHA.segment1                              po_number                     --�����ԍ��i��������Ȃ̂Ŕ����ԍ��͕K�����݂���j
                 ,NVL( XRART.rcv_rtn_number, 'Dummy' )      rcv_rtn_number                --����ԕi�ԍ��i�ԕi�f�[�^�Ȃ̂ŕԕi�ԍ����K�����݂���j
                 ,PLA.line_num                              line_num                      --���הԍ�
                 ,IIMB.item_id                              item_id                       --�i��ID(OPM�i��ID)
                 ,PLA.unit_price                            unit_price                    --�P��
                 ,PLA.quantity * -1                         quantity                      --����
                 ,PLA.attribute1                            lot_no                        --���b�g�ԍ�
                 ,PLA.attribute2                            factory_code                  --�H��R�[�h
                 ,PLA.attribute3                            futai_code                    --�t�уR�[�h
                 ,TO_NUMBER( PLA.attribute4  )              pack_qty                      --�݌ɓ���
                 ,0                                         request_qty                   --�˗�����
                 ,NULL                                      request_uom                   --�˗����ʒP�ʃR�[�h
                 ,TO_DATE( PLA.attribute5 )                 vendor_dlvr_date              --�d����o�ד�
                 ,TO_NUMBER( PLA.attribute6  ) * -1         vendor_dlvr_qty               --�d����o�א���
                 ,TO_NUMBER( PLA.attribute7  ) * -1         rcv_qty                       --�������
                 ,TO_NUMBER( PLA.attribute8  )              purchase_amt                  --�d���艿
                 ,TO_DATE( PLA.attribute9 )                 date_reserved                 --���t�w��
                 ,PLA.attribute10                           order_uom                     --�����P��
                 ,TO_NUMBER( PLA.attribute11 ) * -1         order_qty                     --��������
                 ,PLA.attribute12                           party_dlvr_to                 --�����݌ɓ��ɐ�
                 ,PLA.attribute13                           fix_qty_flg                   --���ʊm��t���O
                 ,PLA.attribute14                           fix_amt_flg                   --���z�m��t���O
                 ,PLA.cancel_flag                           cancel_flg                    --����t���O
                 ,PLA.attribute15                           description                   --�E�v
                 ,PLA.created_by                            h_created_by                  --����_�쐬��
                 ,PLA.creation_date                         h_creation_date               --����_�쐬��
                 ,PLA.last_updated_by                       h_last_updated_by             --����_�ŏI�X�V��
                 ,PLA.last_update_date                      h_last_update_date            --����_�ŏI�X�V��
                 ,PLA.last_update_login                     h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,XRART.txns_date                           u_txns_date                   --������ѓ�
                 ,XRART.uom                                 u_uom                         --����P��
                 ,XRART.rcv_rtn_quantity * -1               u_rcv_rtn_quantity            --����ԕi����
                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --����ԕi�P��
                 ,XRART.conversion_factor                   u_conversion_factor           --����ԕi���Z����
                 ,XRART.kobiki_rate                         kobiki_rate                   --������
                 ,XRART.kobki_converted_unit_price          kobki_converted_unit_price    --������P��
                 ,XRART.kousen_type                         kousen_type                   --���K�敪
                 ,XRART.kousen_rate_or_unit_price           kousen_rate_or_unit_price     --���K
                 ,XRART.kousen_price * -1                   kousen_price                  --�a����K���z
                 ,XRART.fukakin_type                        fukakin_type                  --���ۋ��敪
                 ,XRART.fukakin_rate_or_unit_price          fukakin_rate_or_unit_price    --���ۋ�
                 ,XRART.fukakin_price * -1                  fukakin_price                 --���ۋ��z
-- 2012/07/23 H.Nakamura Del Start E_�{�ғ�_09828
--                 ,XRART.kobki_converted_price * -1          kobki_converted_price         --��������z
-- 2012/07/23 H.Nakamura Del End E_�{�ғ�_09828
-- 2012/07/23 H.Nakamura Add Start E_�{�ғ�_09828
                 ,ROUND(NVL( TO_NUMBER( XRART.kobki_converted_unit_price ), 0 ) * NVL( XRART.quantity, 0 ) * -1)
                                                            kobki_converted_price         --��������z�i������P���~����ԕi����(�A�h�I��).���ʁj
-- 2012/07/23 H.Nakamura Add End E_�{�ғ�_09828
                 ,XRART.created_by                          u_created_by                  --���_�쐬��
                 ,XRART.creation_date                       u_creation_date               --���_�쐬��
                 ,XRART.last_updated_by                     u_last_updated_by             --���_�ŏI�X�V��
                 ,XRART.last_update_date                    u_last_update_date            --���_�ŏI�X�V��
                 ,XRART.last_update_login                   u_last_update_login           --���_�ŏI�X�V���O�C��
                  --���̎擾�p���
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --�[����
            FROM
                  po_headers_all                            PHA                           --�����w�b�_
                 ,po_lines_all                              PLA                           --��������
                 ,mtl_system_items_b                        MSIB                          --INV�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,ic_item_mst_b                             IIMB                          --OPM�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --����ԕi����(�A�h�I��)
           WHERE
             --�����w�b�_�Ƃ̌���
                  PHA.po_header_id                          = PLA.po_header_id
             --INV�i��ID��OPM�i��ID �ϊ�
             AND  PLA.item_id                               = MSIB.inventory_item_id
             AND  MSIB.organization_id                      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MSIB.segment1                             = IIMB.item_no
             --����ԕi���уA�h�I��   �ˊO���������Ȃ�
             AND  XRART.txns_type                           = '2'                         -- ���ы敪:'2:��������ԕi'
             AND  PHA.segment1                              = XRART.source_document_number
             AND  PLA.line_num                              = XRART.source_document_line_num
          --[ ��������ԕi�f�[�^  END ]
        UNION ALL
          --========================================================================
          -- ���������ԕi�f�[�^ �i������ы敪 = '3'�j
          --========================================================================
          SELECT
                  'Dummy'                                   po_number                     --�����ԍ��i�����f�[�^�����Ȃ̂� 'Dummy' �Œ�j
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --����ԕi�ԍ��i�ԕi�f�[�^�Ȃ̂ŕԕi�ԍ����K�����݂���j
                 ,XRART.rcv_rtn_line_number                 line_num                      --���הԍ�
                 ,XRART.item_id                             item_id                       --�i��ID(OPM�i��ID)
                 ,XRART.unit_price                          unit_price                    --�P��
                 ,XRART.quantity * -1                       quantity                      --����
                 ,XRART.lot_number                          lot_no                        --���b�g�ԍ�
                 ,XRART.factory_code                        factory_code                  --�H��R�[�h
                 ,XRART.futai_code                          futai_code                    --�t�уR�[�h
                 ,TO_NUMBER( LOT.attribute6 )               pack_qty                      --�݌ɓ���
                 ,0                                         request_qty                   --�˗�����
                 ,NULL                                      request_uom                   --�˗����ʒP�ʃR�[�h
                 ,NULL                                      vendor_dlvr_date              --�d����o�ד�
                 ,0                                         vendor_dlvr_qty               --�d����o�א���
                 ,0                                         rcv_qty                       --�������
                 ,0                                         purchase_amt                  --�d���艿
                 ,NULL                                      date_reserved                 --���t�w��
                 ,NULL                                      order_uom                     --�����P��
                 ,0                                         order_qty                     --��������
                 ,NULL                                      party_dlvr_to                 --�����݌ɓ��ɐ�
                 ,NULL                                      fix_qty_flg                   --���ʊm��t���O
                 ,NULL                                      fix_amt_flg                   --���z�m��t���O
                 ,'N'                                       cancel_flg                    --����t���O
                 ,NULL                                      description                   --�E�v
                 ,NULL                                      h_created_by                  --����_�쐬��
                 ,NULL                                      h_creation_date               --����_�쐬��
                 ,NULL                                      h_last_updated_by             --����_�ŏI�X�V��
                 ,NULL                                      h_last_update_date            --����_�ŏI�X�V��
                 ,NULL                                      h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,XRART.txns_date                           u_txns_date                   --������ѓ�
                 ,XRART.uom                                 u_uom                         --����P��
                 ,XRART.rcv_rtn_quantity * -1               u_rcv_rtn_quantity            --����ԕi����
                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --����ԕi�P��
                 ,XRART.conversion_factor                   u_conversion_factor           --����ԕi���Z����
                 ,XRART.kobiki_rate                         kobiki_rate                   --������
                 ,XRART.kobki_converted_unit_price          kobki_converted_unit_price    --������P��
                 ,XRART.kousen_type                         kousen_type                   --���K�敪
                 ,XRART.kousen_rate_or_unit_price           kousen_rate_or_unit_price     --���K
                 ,XRART.kousen_price * -1                   kousen_price                  --�a����K���z
                 ,XRART.fukakin_type                        fukakin_type                  --���ۋ��敪
                 ,XRART.fukakin_rate_or_unit_price          fukakin_rate_or_unit_price    --���ۋ�
                 ,XRART.fukakin_price * -1                  fukakin_price                 --���ۋ��z
-- 2012/07/23 H.Nakamura Del Start E_�{�ғ�_09828
--                 ,XRART.kobki_converted_price * -1          kobki_converted_price         --��������z
-- 2012/07/23 H.Nakamura Del End E_�{�ғ�_09828
-- 2012/07/23 H.Nakamura Add Start E_�{�ғ�_09828
                 ,ROUND(NVL( TO_NUMBER( XRART.kobki_converted_unit_price ), 0 ) * NVL( XRART.quantity, 0 ) * -1)
                                                            kobki_converted_price         --��������z�i������P���~����ԕi����(�A�h�I��).���ʁj
-- 2012/07/23 H.Nakamura Add End E_�{�ғ�_09828
                 ,XRART.created_by                          u_created_by                  --���_�쐬��
                 ,XRART.creation_date                       u_creation_date               --���_�쐬��
                 ,XRART.last_updated_by                     u_last_updated_by             --���_�ŏI�X�V��
                 ,XRART.last_update_date                    u_last_update_date            --���_�ŏI�X�V��
                 ,XRART.last_update_login                   u_last_update_login           --���_�ŏI�X�V���O�C��
                  --���̎擾�p���
                 ,XRART.txns_date                           deliver_date                  --�[����
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART                         --����ԕi����(�A�h�I��)
                 ,ic_lots_mst                               LOT                           --���b�g�}�X�^
           WHERE
                  XRART.txns_type                           = '3'                         --���ы敪:'3:���������ԕi'
             --���b�g�}�X�^�Ƃ̌���
             AND  XRART.item_id                             = LOT.item_id(+)
             AND  XRART.lot_id                              = LOT.lot_id(+)
          --[ ���������ԕi�f�[�^  END ]
       )                                          POL                           --����������׃f�[�^
       ------------------------------------------
       -- �ȉ��A���̎擾�p
       ------------------------------------------
       ,xxskz_item_mst2_v                         ITEM                          --SKYLINK�p����VIEW �i�ڃ}�X�^VIEW2
       ,xxskz_prod_class_v                        PRODC                         --���i�敪�擾�p
       ,xxskz_item_class_v                        ITEMC                         --�i�ڋ敪�擾�p
       ,xxskz_crowd_code_v                        CROWD                         --�Q�R�[�h�擾�p
       ,ic_lots_mst                               LOT                           --���b�g���擾�p
       ,xxskz_vendor_sites2_v                     VDST                          --SKYLINK�p����VIEW �d����T�C�g���VIEW2(�H�ꖼ)
       ,xxskz_item_locations_v                    ILOC                          --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�����݌ɓ��ɐ於)
       ,fnd_user                                  FU_CB_H                       --���[�U�[�}�X�^(����_created_by���̎擾�p)
       ,fnd_user                                  FU_LU_H                       --���[�U�[�}�X�^(����_last_updated_by���̎擾�p)
       ,fnd_user                                  FU_LL_H                       --���[�U�[�}�X�^(����_last_update_login���̎擾�p)
       ,fnd_logins                                FL_LL_H                       --���O�C���}�X�^(����_last_update_login���̎擾�p)
       ,fnd_user                                  FU_CB_U                       --���[�U�[�}�X�^(����ԕi_created_by���̎擾�p)
       ,fnd_user                                  FU_LU_U                       --���[�U�[�}�X�^(����ԕi_last_updated_by���̎擾�p)
       ,fnd_user                                  FU_LL_U                       --���[�U�[�}�X�^(����ԕi_last_update_login���̎擾�p)
       ,fnd_logins                                FL_LL_U                       --���O�C���}�X�^(����ԕi_last_update_login���̎擾�p)
       ,fnd_lookup_values                         FLV01                         --�N�C�b�N�R�[�h(���ʊm��t���O��)
       ,fnd_lookup_values                         FLV02                         --�N�C�b�N�R�[�h(���z�m��t���O��)
       ,fnd_lookup_values                         FLV03                         --�N�C�b�N�R�[�h(����t���O��)
       ,fnd_lookup_values                         FLV04                         --�N�C�b�N�R�[�h(���K�敪��)
       ,fnd_lookup_values                         FLV05                         --�N�C�b�N�R�[�h(���ۋ��敪��)
 WHERE
   --�i�ڏ��擾
        POL.item_id                               = ITEM.item_id(+)
   AND  NVL( POL.deliver_date, SYSDATE )         >= ITEM.start_date_active(+)
   AND  NVL( POL.deliver_date, SYSDATE )         <= ITEM.end_date_active(+)
   --�i�ڃJ�e�S�����擾
   AND  POL.item_id                               = PRODC.item_id(+)            --���i�敪
   AND  POL.item_id                               = ITEMC.item_id(+)            --�i�ڋ敪
   AND  POL.item_id                               = CROWD.item_id(+)            --�Q�R�[�h
   --���b�g���擾
   AND  POL.item_id                               = LOT.item_id(+)
   AND  POL.lot_no                                = LOT.lot_no(+)
   --�H�ꖼ�擾
   AND  POL.factory_code                          = VDST.vendor_site_code(+)
   AND  NVL( POL.deliver_date, SYSDATE )         >= VDST.start_date_active(+)
   AND  NVL( POL.deliver_date, SYSDATE )         <= VDST.end_date_active(+)
   --�����݌ɓ��ɐ於�擾
   AND  POL.party_dlvr_to                         = ILOC.segment1(+)
   --�������ׂ�WHO�J�������擾
   AND  POL.h_created_by                          = FU_CB_H.user_id(+)
   AND  POL.h_last_updated_by                     = FU_LU_H.user_id(+)
   AND  POL.h_last_update_login                   = FL_LL_H.login_id(+)
   AND  FL_LL_H.user_id                           = FU_LL_H.user_id(+)
   --����ԕi���ׂ�WHO�J�������擾
   AND  POL.u_created_by                          = FU_CB_U.user_id(+)
   AND  POL.u_last_updated_by                     = FU_LU_U.user_id(+)
   AND  POL.u_last_update_login                   = FL_LL_U.login_id(+)
   AND  FL_LL_U.user_id                           = FU_LL_U.user_id(+)
   --�y�N�C�b�N�R�[�h�z���ʊm��t���O��
   AND  FLV01.language(+)                         = 'JA'
   AND  FLV01.lookup_type(+)                      = 'XXCMN_YESNO'
   AND  FLV01.lookup_code(+)                      = POL.fix_qty_flg
   --�y�N�C�b�N�R�[�h�z���z�m��t���O��
   AND  FLV02.language(+)                         = 'JA'
   AND  FLV02.lookup_type(+)                      = 'XXCMN_YESNO'
   AND  FLV02.lookup_code(+)                      = POL.fix_amt_flg
   --�y�N�C�b�N�R�[�h�z����t���O��
   AND  FLV03.language(+)                         = 'JA'
   AND  FLV03.lookup_type(+)                      = 'XXCMN_YESNO'
   AND  FLV03.lookup_code(+)                      = NVL( POL.cancel_flg, 'N' )
   --�y�N�C�b�N�R�[�h�z���K�敪��
   AND  FLV04.language(+)                         = 'JA'
   AND  FLV04.lookup_type(+)                      = 'XXPO_KOUSEN_TYPE'
   AND  FLV04.lookup_code(+)                      = POL.kousen_type
   --�y�N�C�b�N�R�[�h�z���ۋ��敪��
   AND  FLV05.language(+)                         = 'JA'
   AND  FLV05.lookup_type(+)                      = 'XXPO_FUKAKIN_TYPE'
   AND  FLV05.lookup_code(+)                      = POL.fukakin_type
/
COMMENT ON TABLE APPS.XXSKZ_�����������_��{_V IS 'SKYLINK�p����������ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�����ԍ� IS '�����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����ԕi�ԍ� IS '����ԕi�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���הԍ� IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���b�g�ԍ� IS '���b�g�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�����N���� IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�ŗL�L�� IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�ܖ����� IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�H��R�[�h IS '�H��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�H�ꖼ IS '�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�t�уR�[�h IS '�t�уR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�݌ɓ��� IS '�݌ɓ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�˗����� IS '�˗�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�˗����ʒP�ʃR�[�h IS '�˗����ʒP�ʃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�d����o�ד� IS '�d����o�ד�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�d����o�א��� IS '�d����o�א���'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.������� IS '�������'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�d���艿 IS '�d���艿'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���t�w�� IS '���t�w��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�����P�� IS '�����P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�������� IS '��������'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�����݌ɓ��ɐ� IS '�����݌ɓ��ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�����݌ɓ��ɐ於 IS '�����݌ɓ��ɐ於'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���ʊm��t���O IS '���ʊm��t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���ʊm��t���O�� IS '���ʊm��t���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���z�m��t���O IS '���z�m��t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���z�m��t���O�� IS '���z�m��t���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����t���O IS '����t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����t���O�� IS '����t���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�E�v IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����_�쐬�� IS '����_�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����_�쐬�� IS '����_�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����_�ŏI�X�V�� IS '����_�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����_�ŏI�X�V�� IS '����_�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����_�ŏI�X�V���O�C�� IS '����_�ŏI�X�V���O�C��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.������ѓ� IS '������ѓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����P�� IS '����P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����ԕi���� IS '����ԕi����'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����ԕi�P�� IS '����ԕi�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.����ԕi���Z���� IS '����ԕi���Z����'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.������P�� IS '������P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���K�敪 IS '���K�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���K�敪�� IS '���K�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���K IS '���K'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.�a����K���z IS '�a����K���z'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���ۋ��敪 IS '���ۋ��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���ۋ��敪�� IS '���ۋ��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���ۋ� IS '���ۋ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���ۋ��z IS '���ۋ��z'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.��������z IS '��������z'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���_�쐬�� IS '���_�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���_�쐬�� IS '���_�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���_�ŏI�X�V�� IS '���_�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���_�ŏI�X�V�� IS '���_�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�����������_��{_V.���_�ŏI�X�V���O�C�� IS '���_�ŏI�X�V���O�C��'
/
