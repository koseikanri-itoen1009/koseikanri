CREATE OR REPLACE VIEW APPS.XXSKY_�h�����N�݌Ɏ���_��{_V
(
 �Ώ۔N��
,�q�ɃR�[�h
,�q�ɖ�
,�ۊǏꏊ�R�[�h
,�ۊǏꏊ��
,�ۊǏꏊ����
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i��
,�i�ږ�
,�i�ڗ���
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�����
,�I���P�[�X��
,�I���o����
,�ϑ����݌ɃP�[�X��
,�ϑ����݌Ƀo����
,�_��_�����݌ɃP�[�X��
,�_��_�����݌Ƀo����
,�ԕi_���ԓ��ɃP�[�X��
,�ԕi_���ԓ��Ƀo����
,���Y_���ԓ��ɃP�[�X��
,���Y_���ԓ��Ƀo����
,�ړ�_���ԓ��ɃP�[�X��
,�ړ�_���ԓ��Ƀo����
,���̑�_���ԓ��ɃP�[�X��
,���̑�_���ԓ��Ƀo����
,���__���ԏo�ɃP�[�X��
,���__���ԏo�Ƀo����
,�ړ�_���ԏo�ɃP�[�X��
,�ړ�_���ԏo�Ƀo����
,���̑�_���ԏo�ɃP�[�X��
,���̑�_���ԏo�Ƀo����
)
AS
SELECT
        STRN.yyyymm                                         yyyymm              --�N��
       ,STRN.whse_code                                      whse_code           --�q�ɃR�[�h
       ,IWM.whse_name                                       whse_name           --�q�ɖ�
       ,STRN.location                                       location            --�ۊǏꏊ�R�[�h
       ,ILOC.description                                    loct_name           --�ۊǏꏊ��
       ,ILOC.short_name                                     loct_s_name         --�ۊǏꏊ����
       ,PRODC.prod_class_code                               prod_class_code     --���i�敪
       ,PRODC.prod_class_name                               prod_class_name     --���i�敪��
       ,ITEMC.item_class_code                               item_class_code     --�i�ڋ敪
       ,ITEMC.item_class_name                               item_class_name     --�i�ڋ敪��
       ,CROWD.crowd_code                                    crowd_code          --�Q�R�[�h
       ,ITEM.item_no                                        item_code           --�i��
       ,ITEM.item_name                                      item_name           --�i�ږ�
       ,ITEM.item_short_name                                item_s_name         --�i�ڗ���
       ,ILM.lot_no                                          lot_no              --���b�gNo
       ,ILM.attribute1                                      lot_date            --�����N����
       ,ILM.attribute2                                      lot_sign            --�ŗL�L��
       ,ILM.attribute3                                      best_bfr_date       --�ܖ�����
       ,NVL( STRN.stc_r_cs_qty, 0 )                         stc_r_cs_qty        --�I���P�[�X��
       ,NVL( STRN.stc_r_qty   , 0 )                         stc_r_qty           --�I���o����
       ,NVL( TRUNC( STRN.cargo_qty   / ITEM.num_of_cases ), 0 )
                                                            cargo_cs_qty        --�ϑ����P�[�X��
       ,NVL( STRN.cargo_qty   , 0 )                         cargo_qty           --�ϑ����o����
       ,NVL( TRUNC( STRN.month_qty   / ITEM.num_of_cases ), 0 )
                                                            month_cs_qty        --�_��_�����݌ɃP�[�X��
       ,NVL( STRN.month_qty   , 0 )                         month_qty           --�_��_�����݌Ƀo����
       ,NVL( TRUNC( STRN.rev_in_qty  / ITEM.num_of_cases ), 0 )
                                                            rev_in_cs_qty       --�ԕi_���ԓ��ɃP�[�X��(����ԕi)
       ,NVL( STRN.rev_in_qty  , 0 )                         rev_in_qty          --�ԕi_���ԓ��Ƀo����(����ԕi)
       ,NVL( TRUNC( STRN.po_in_qty   / ITEM.num_of_cases ), 0 )
                                                            po_in_cs_qty        --���Y_���ԓ��ɃP�[�X��(���)
       ,NVL( STRN.po_in_qty   , 0 )                         po_in_qty           --���Y_���ԓ��Ƀo����(���)
       ,NVL( TRUNC( STRN.mov_in_qty  / ITEM.num_of_cases ), 0 )
                                                            mov_in_cs_qty       --�ړ�_���ԓ��ɃP�[�X��
       ,NVL( STRN.mov_in_qty  , 0 )                         mov_in_qty          --�ړ�_���ԓ��Ƀo����
       ,NVL( TRUNC( STRN.etc_in_qty  / ITEM.num_of_cases ), 0 )
                                                            etc_in_cs_qty       --���̑�_���ԓ��ɃP�[�X��
       ,NVL( STRN.etc_in_qty  , 0 )                         etc_in_qty          --���̑�_���ԓ��Ƀo����
       ,NVL( TRUNC( STRN.oe_out_qty  / ITEM.num_of_cases ), 0 )
                                                            oe_out_cs_qty       --���__���ԏo�ɃP�[�X��(�o��)
       ,NVL( STRN.oe_out_qty  , 0 )                         oe_out_qty          --���__���ԏo�Ƀo����(�o��)
       ,NVL( TRUNC( STRN.mov_out_qty / ITEM.num_of_cases ), 0 )
                                                            mov_out_cs_qty      --�ړ�_���ԏo�ɃP�[�X��
       ,NVL( STRN.mov_out_qty , 0 )                         mov_out_qty         --�ړ�_���ԏo�Ƀo����
       ,NVL( TRUNC( STRN.etc_out_qty / ITEM.num_of_cases ), 0 )
                                                            etc_out_cs_qty      --���̑�_���ԏo�ɃP�[�X��
       ,NVL( STRN.etc_out_qty , 0 )                         etc_out_qty         --���̑�_���ԏo�Ƀo����
  FROM
        (  --�N���A�q�ɃR�[�h�A�ۊǏꏊ�R�[�h�A�i��ID�A���b�gID�P�ʂŏW�v
           SELECT
                    TRAN.yyyymm                             yyyymm              --�N��
                   ,TRAN.whse_code                          whse_code           --�q�ɃR�[�h
                   ,TRAN.location                           location            --�ۊǏꏊ�R�[�h
                   ,TRAN.item_id                            item_id             --�i��ID
                   ,TRAN.lot_id                             lot_id              --���b�gID
                   ,SUM( TRAN.stc_r_cs_qty )                stc_r_cs_qty        --�I���P�[�X��
                   ,SUM( TRAN.stc_r_qty    )                stc_r_qty           --�I���o����
                   ,SUM( TRAN.cargo_qty    )                cargo_qty           --�ϑ����o����
                    --�����݌ɐ��͒I�������݌Ƀe�[�u���̍ő�N���̎����܂ł��o�͂���i����ȍ~�͌���݌ɐ����擾���Ȃ��̂ŋ��܂�Ȃ��j
                   ,SUM( CASE WHEN TRAN.yyyymm <= MYM.yyyymm THEN TRAN.month_qty END )
                                                            month_qty           --�����݌Ƀo����
                   ,SUM( TRAN.rev_in_qty   )                rev_in_qty          --�ԕi_���ԓ��Ƀo����(����ԕi)
                   ,SUM( TRAN.po_in_qty    )                po_in_qty           --���Y_���ԓ��Ƀo����(���)
                   ,SUM( TRAN.mov_in_qty   )                mov_in_qty          --�ړ�_���ԓ��Ƀo����
                   ,SUM( TRAN.etc_in_qty   )                etc_in_qty          --���̑�_���ԓ��Ƀo����
                   ,SUM( TRAN.oe_out_qty   )                oe_out_qty          --���__���ԏo�Ƀo����(�o��)
                   ,SUM( TRAN.mov_out_qty  )                mov_out_qty         --�ړ�_���ԏo�Ƀo����
                   ,SUM( TRAN.etc_out_qty  )                etc_out_qty         --���̑�_���ԏo�Ƀo����
             FROM
                   ( --======================================================================
                     -- �I�����ʃA�h�I������I���݌ɐ����擾
                     --======================================================================
                      SELECT
                              TO_CHAR( XSIR.invent_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XSIR.invent_whse_code         whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,XSIR.item_id                  item_id             --�i��ID
                             ,XSIR.lot_id                   lot_id              --���b�gID
                             ,TRUNC( NVL( XSIR.case_amt, 0 ) + ( NVL( XSIR.loose_amt, 0 ) / DECODE( XSIR.content, NULL, 1, 0, 1, XSIR.content ) ) )
                                                            stc_r_cs_qty        --�I���P�[�X�� (�I�����ʃA�h�I���e�[�u���̂݃P�[�X���ƃo�����̘a�ő����ƂȂ��Ă���)
                             ,( NVL( XSIR.case_amt, 0 ) * NVL( XSIR.content, 0 ) ) + NVL( XSIR.loose_amt, 0 )
                                                            stc_r_qty           --�I���o����   (�I�����ʃA�h�I���e�[�u���̂݃P�[�X���ƃo�����̘a�ő����ƂȂ��Ă���)
                             ,0                             cargo_qty           --�ϑ����o����
                             ,0                             month_qty           --�����݌Ƀo����
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxinv_stc_inventory_result    XSIR                --�I�����ʃA�h�I��
                             ,xxsky_item_locations_v        XILV                --�ۊǏꏊ�擾�p
                       WHERE
                            ( XSIR.case_amt <> 0  OR  XSIR.loose_amt <> 0 )
                         AND  XSIR.invent_whse_code         = XILV.whse_code
                         AND  XILV.allow_pickup_flag        = '1'               --�o�׈����Ώۃt���O
                     --<< �I�����ʃA�h�I������I���݌ɐ����擾 END >>--
                    UNION ALL
                     --======================================================================
                     -- �I�������݌Ƀe�[�u�����猎��݌ɐ��Ƃ��đO���̌����݌ɐ����擾
                     --   �ˁy�O���̌����݌Ɂ{�����̓��o�ɐ��̐ςݏグ�z�ɂ���ē����̌����݌ɐ������߂�
                     --======================================================================
                      SELECT
                              TO_CHAR( ADD_MONTHS( TO_DATE( XSIM.invent_ym || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' )    --�O���̌����݌ɐ��𓖌��̌���݌ɐ��Ƃ��Ĉ���
                                                            yyyymm              --�N��
                             ,XSIM.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,XSIM.item_id                  item_id             --�i��ID
                             ,XSIM.lot_id                   lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,NVL( XSIM.monthly_stock, 0 ) + NVL( XSIM.cargo_stock, 0 )
                                                            month_qty           --�����݌Ƀo����
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxinv_stc_inventory_month_stck    XSIM            --�I�������݌ɃA�h�I��
                             ,xxsky_item_locations_v            XILV            --�ۊǏꏊ�擾�p
                       WHERE
                            ( XSIM.cargo_stock <> 0  OR  XSIM.monthly_stock <> 0 )
                         AND  XSIM.whse_code                = XILV.whse_code
                         AND  XILV.allow_pickup_flag        = '1'               --�o�׈����Ώۃt���O
                     --<< �I�������݌Ƀe�[�u���猎��݌ɐ��Ƃ��đO���̌����݌ɐ����擾 END >>--
                    UNION ALL
                     --======================================================================
                     -- �e�g�����U�N�V��������ϑ��������擾
                     --  �P�D�ړ��o�Ɏ��сi�ϑ����̂݁j
                     --  �Q�D�o�׎��сi�ϑ����̂݁j
                     --  �R�D�x�����сi�ϑ����̂݁j
                     --======================================================================
                      ----------------------------------------------------------------------
                      -- �P�D�ړ��o�Ɏ��сi�ϑ����̂݁j
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XMH.actual_ship_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XMH.shipped_locat_code        location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,XMD.actual_quantity           cargo_qty           --�ϑ����o����
                             ,0                             month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxinv_mov_req_instr_headers   XMH                 --�ړ��˗�/�w���w�b�_(�A�h�I��)
                             ,xxinv_mov_req_instr_lines     XML                 --�ړ��˗�/�w������(�A�h�I��)
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�(�A�h�I��)
                             ,xxsky_item_locations_v        XIL                 --OPM�ۊǏꏊ���VIEW
                             ,xxsky_item_locations_v        XIL_TO              --OPM�ۊǏꏊ���VIEW -- 2010/03/09 H.Itou Add E_�{�ғ�_01822
                       WHERE
                         -- �o�ɓ��̔N�� < ���ɓ��̔N��   �c�ϑw���Ɣ��f
                              TO_CHAR( XMH.actual_ship_date, 'YYYYMM' ) 
                            < TO_CHAR( NVL( XMH.actual_arrival_date, XMH.schedule_arrival_date ), 'YYYYMM' )
                         -- �ړ��˗�/�w���w�b�_(�A�h�I��)�̏���
                         AND  XMH.status                    IN ( '06', '04' )   --06:���o�ɕ񍐗L�A04:�o�ɕ񍐗L
                         -- �ړ��˗�/�w������(�A�h�I��)�Ƃ̌���
                         AND  XML.delete_flg                = 'N'               --OFF
                         AND  XMH.mov_hdr_id                = XML.mov_hdr_id
                         -- �ړ����b�g�ڍ�(�A�h�I��)�Ƃ̌���
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '20'              --�ړ�
                         AND  XMD.record_type_code          = '20'              --�o�Ɏ���
                         AND  XML.mov_line_id               = XMD.mov_line_id
                         -- �ۊǏꏊ���擾
                         AND  XMH.shipped_locat_id          = XIL.inventory_location_id
                         AND  XMH.ship_to_locat_id          = XIL_TO.inventory_location_id -- 2010/03/09 H.Itou Add E_�{�ғ�_01822
                         AND  XIL.whse_code                <> XIL_TO.whse_code             -- 2010/03/09 H.Itou Add E_�{�ғ�_01822 ����q�Ɉړ��͑ΏۊO
                      --[ �P�D�ړ��o�Ɏ��сi�ϑw���̂݁j END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �Q�D�o�׎��сi�ϑ����̂݁j
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XOH.deliver_from              location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,XMD.actual_quantity           cargo_qty           --�ϑ����o����
                             ,0                             month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxwsh_order_headers_all       XOH                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         XOL                 --�󒍖���
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTA                 --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XIL                 --�ۊǏꏊ�}�X�^
                       WHERE
                         -- �o�ɓ��̔N�� < ���ɓ��̔N��   �c�ϑw���Ɣ��f
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' ) 
                            < TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                         --�󒍃w�b�_�̏���
                         AND  XOH.req_status                = '04'              --���ьv���
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���
                         AND  OTA.attribute1                = '1'               --�o�׈˗�
                         AND  OTA.order_category_code       = 'ORDER'
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --�o�׈˗�
                         AND  XMD.record_type_code          = '20'              --�o�Ɏ���
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ �Q�D�o�׎��сi�ϑ����̂݁j END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �R�D�x�����сi�ϑ����̂݁j
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XOH.deliver_from              location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'RETURN', -1, 1 )
                                                            cargo_qty           --�ϑ����o����
                             ,0                             month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxwsh_order_headers_all       XOH                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         XOL                 --�󒍖���
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTA                 --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XIL                 --�ۊǏꏊ�}�X�^
                       WHERE
                         -- �o�ɓ��̔N�� < ���ɓ��̔N��   �c�ϑw���Ɣ��f
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' ) 
                            < TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                         --�󒍃w�b�_�̏���
                         AND  XOH.req_status                = '08'              --���ьv���
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���
                         AND  OTA.attribute1                = '2'               --�x���˗�
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '30'              --�x���w��
                         AND  XMD.record_type_code          = '20'              --�o�Ɏ���
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ �R�D�x�����сi�ϑ����̂݁j END ]--
                     --<< �e�g�����U�N�V��������ϑw�������擾 END >>--
                    UNION ALL
                     --======================================================================
                     -- �e�g�����U�N�V�������猎�ԓ��ɐ����擾
                     --  �P�D�d����ԕi
                     --  �Q�D�����������
                     --  �R�D�ړ����Ɏ���
                     --  �S�D�q�֕ԕi���Ɏ���
                     --  �T�D���̑�����
                     --======================================================================
                      ----------------------------------------------------------------------
                      -- �P�D�d����ԕi  �c�}�C�i�X�l�ŏo��
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( ITC.trans_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,ITC.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITC.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITC.item_id                   item_id             --�i��ID
                             ,ITC.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,ITC.trans_qty                 month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,ITC.trans_qty                 rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxcmn_rcv_pay_mst             XRP                 --�󕥋敪�A�h�I���}�X�^
                             ,ic_adjs_jnl                   IAJ                 --OPM�݌ɒ����W���[�i��
                             ,ic_jrnl_mst                   IJM                 --OPM�W���[�i���}�X�^
                             ,ic_tran_cmp                   ITC                 --OPM�����݌Ƀg�����U�N�V����
                       WHERE
                         -- �󕥋敪�A�h�I���}�X�^�̏���
                              XRP.doc_type                  = 'ADJI'
                         AND  XRP.reason_code               = 'X201'            --�d���ԕi�o��
                         AND  XRP.rcv_pay_div               = '1'               --���
                         AND  XRP.use_div_invent            = 'Y'
                         -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITC.trans_qty                <> 0
                         AND  ITC.doc_type                  = XRP.doc_type
                         AND  ITC.reason_code               = XRP.reason_code
                         -- OPM�݌ɒ����W���[�i���Ƃ̌���
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPM�W���[�i���}�X�^�Ƃ̌���
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ �P�D�d����ԕi END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �Q�D�����������
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XRT.txns_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,PHA.attribute5                location            --�ۊǏꏊ�R�[�h
                             ,XRT.item_id                   item_id             --�i��ID
                             ,XRT.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,XRT.quantity                  month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,XRT.quantity                  po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              po_headers_all                PHA                 --�����w�b�_
                             ,po_lines_all                  PLA                 --��������
                             ,xxpo_rcv_and_rtn_txns         XRT                 --����ԕi����(�A�h�I��)
                             ,xxsky_item_locations_v        XIL                 --OPM�ۊǏꏊ���VIEW
                       WHERE
                         -- �����w�b�_�̏���
                              PHA.attribute1                IN ( '25'           --�������
                                                               , '30'           --���ʊm���
                                                               , '35' )         --���z�m���
                         -- �������ׂƂ̌���
                         AND  PLA.attribute13               = 'Y'               --������
                         AND  PLA.cancel_flag              <> 'Y'               --�L�����Z���ȊO
                         AND  PHA.po_header_id              = PLA.po_header_id
                         -- ����ԕi����(�A�h�I��)�Ƃ̌���
                         AND  XRT.txns_type                 = '1'               --���
                         AND  XRT.quantity                 <> 0
                         AND  PHA.segment1                  = XRT.source_document_number
                         AND  PLA.line_num                  = XRT.source_document_line_num
                         -- �ۊǏꏊ���擾
                         AND  PHA.attribute5                = XIL.segment1
                      --[ �Q�D����������� END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �R�D�ړ����Ɏ���
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XMH.actual_arrival_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XMH.ship_to_locat_code        location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,XMD.actual_quantity           month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,XMD.actual_quantity           mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxinv_mov_req_instr_headers   XMH                 --�ړ��˗�/�w���w�b�_(�A�h�I��)
                             ,xxinv_mov_req_instr_lines     XML                 --�ړ��˗�/�w������(�A�h�I��)
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�(�A�h�I��)
                             ,xxsky_item_locations_v        XIL                 --OPM�ۊǏꏊ���VIEW
                             ,xxsky_item_locations_v        XIL_FROM            --OPM�ۊǏꏊ���VIEW -- 2010/03/09 H.Itou Add E_�{�ғ�_01822
                       WHERE
                         -- �ړ��˗�/�w���w�b�_(�A�h�I��)�̏���
                              XMH.status                    IN ( '06', '05' )   --06:���o�ɕ񍐗L�A05:���ɕ񍐗L
                         -- �ړ��˗�/�w������(�A�h�I��)�Ƃ̌���
                         AND  XML.delete_flg                = 'N'               --OFF
                         AND  XMH.mov_hdr_id                = XML.mov_hdr_id
                         -- �ړ����b�g�ڍ�(�A�h�I��)�Ƃ̌���
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '20'              --�ړ�
                         AND  XMD.record_type_code          = '30'              --���Ɏ���
                         AND  XML.mov_line_id               = XMD.mov_line_id
                         -- �ۊǏꏊ���擾
                         AND  XMH.ship_to_locat_id          = XIL.inventory_location_id
                         AND  XMH.shipped_locat_id          = XIL_FROM.inventory_location_id -- 2010/03/09 H.Itou Add E_�{�ғ�_01822
                         AND  XIL.whse_code                <> XIL_FROM.whse_code             -- 2010/03/09 H.Itou Add E_�{�ғ�_01822 ����q�Ɉړ��͑ΏۊO
                      --[ �R�D�ړ����Ɏ��� END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �S�D�q�֕ԕi���Ɏ���
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XOH.deliver_from              location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'ORDER', -1, 1 )    --����Ȃ�o�Ɉ���
                                                            month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'ORDER', -1, 1 )    --����Ȃ�o��(���ɂ̃}�C�i�X)����
                                                            etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxwsh_order_headers_all       XOH                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         XOL                 --�󒍖���
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTA                 --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XIL                 --�ۊǏꏊ�}�X�^
                       WHERE
                         --�󒍃w�b�_�̏���
                              XOH.req_status                = '04'              --���ьv���
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���
                         AND  OTA.attribute1                = '3'               --�q�֕ԕi
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --�o�׈˗�
                         AND  XMD.record_type_code          = '20'              --�o�Ɏ���
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ �S�D�q�֕ԕi���Ɏ��� END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �T�D���̑�����
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( ITC.trans_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,ITC.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITC.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITC.item_id                   item_id             --�i��ID
                             ,ITC.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,ITC.trans_qty                 month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,ITC.trans_qty                 etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxcmn_rcv_pay_mst             XRP                 --�󕥋敪�A�h�I���}�X�^
                             ,ic_adjs_jnl                   IAJ                 --OPM�݌ɒ����W���[�i��
                             ,ic_jrnl_mst                   IJM                 --OPM�W���[�i���}�X�^
                             ,ic_tran_cmp                   ITC                 --OPM�����݌Ƀg�����U�N�V����
                       WHERE
                         -- �󕥋敪�A�h�I���}�X�^�̏���
                              XRP.doc_type                  = 'ADJI'
                         AND  XRP.reason_code              <> 'X977'            --�����݌�
                         AND  XRP.reason_code              <> 'X988'            --�l������
                         AND  XRP.reason_code              <> 'X123'            --�ړ����ђ����i�o�Ɂj
                         AND  XRP.reason_code              <> 'X201'            --�d����ԕi
                         AND  XRP.rcv_pay_div               = '1'               --���
                         AND  XRP.use_div_invent            = 'Y'
                         -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITC.trans_qty                <> 0
                         AND  XRP.doc_type                  = ITC.doc_type
                         AND  XRP.reason_code               = ITC.reason_code
                         -- OPM�݌ɒ����W���[�i���Ƃ̌���
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPM�W���[�i���}�X�^�Ƃ̌���
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ �T�D���̑����� END ]--
                     --<< �e�g�����U�N�V�������猎�ԓ��ɐ����擾 END >>--
                    UNION ALL
                     --======================================================================
                     -- �e�g�����U�N�V�������猎�ԏo�ɐ����擾
                     --  �P�D�o�׎���
                     --  �Q�D�L���x������
                     --  �R�D���{��p���o�׎���
                     --  �S�D�ړ����Ɏ���
                     --  �T�D���̑��o��
                     --======================================================================
                      ----------------------------------------------------------------------
                      -- �P�D�o�׎���
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XOH.deliver_from              location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,XMD.actual_quantity * -1      month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,XMD.actual_quantity           oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxwsh_order_headers_all       XOH                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         XOL                 --�󒍖���
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTA                 --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XIL                 --�ۊǏꏊ�}�X�^
                       WHERE
                         --�󒍃w�b�_�̏���
                              XOH.req_status                = '04'              --���ьv���
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���
                         AND  OTA.attribute1                = '1'               --�o�׈˗�
                         AND  OTA.attribute4                = '1'               --�ʏ�o��
                         AND  OTA.order_category_code       = 'ORDER'
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --�o�׈˗�
                         AND  XMD.record_type_code          = '20'              --�o�Ɏ���
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ �P�D�o�ץ�q�Ԏ��� END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �Q�D�L���x������
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XOH.deliver_from              location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'RETURN', 1, -1 )    --�ԕi�Ȃ���Ɉ���
                                                            month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�Ȃ����(�o�ɂ̃}�C�i�X)����
                                                            oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxwsh_order_headers_all       XOH                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         XOL                 --�󒍖���
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTA                 --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XIL                 --�ۊǏꏊ�}�X�^
                       WHERE
                         --�󒍃w�b�_�̏���
                              XOH.req_status                = '08'              --���ьv���
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���
                         AND  OTA.attribute1                = '2'               --�x��
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '30'              --�x���w��
                         AND  XMD.record_type_code          = '20'              --�o�Ɏ���
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ �Q�D�L���x������ END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �R�D���{��p���o�׎���
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XOH.deliver_from              location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,XMD.actual_quantity * -1      month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,XMD.actual_quantity           etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxwsh_order_headers_all       XOH                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         XOL                 --�󒍖���
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTA                 --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XIL                 --�ۊǏꏊ�}�X�^
                       WHERE
                         --�󒍃w�b�_�̏���
                              XOH.req_status                = '04'              --���ьv���
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���
                         AND  OTA.attribute1                = '1'               --�o�׈˗�
                         AND  OTA.attribute4                = '2'               --���{��p���o��
                         AND  OTA.order_category_code       = 'ORDER'
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --�o�׈˗�
                         AND  XMD.record_type_code          = '20'              --�o�Ɏ���
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ �R�D�o�ץ�q�Ԏ��� END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �S�D�ړ��o�׎���
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XMH.actual_arrival_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,XIL.whse_code                 whse_code           --�q�ɃR�[�h
                             ,XMH.shipped_locat_code        location            --�ۊǏꏊ�R�[�h
                             ,XMD.item_id                   item_id             --�i��ID
                             ,XMD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,XMD.actual_quantity * -1      month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,XMD.actual_quantity           mov_out_qty         --�ړ�_�o�Ƀo����
                             ,0                             etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxinv_mov_req_instr_headers   XMH                 --�ړ��˗�/�w���w�b�_(�A�h�I��)
                             ,xxinv_mov_req_instr_lines     XML                 --�ړ��˗�/�w������(�A�h�I��)
                             ,xxinv_mov_lot_details         XMD                 --�ړ����b�g�ڍ�(�A�h�I��)
                             ,xxsky_item_locations_v        XIL                 --OPM�ۊǏꏊ���VIEW
                             ,xxsky_item_locations_v        XIL_TO              --OPM�ۊǏꏊ���VIEW -- 2010/03/09 H.Itou Add E_�{�ғ�_01822
                       WHERE
                         -- �ړ��˗�/�w���w�b�_(�A�h�I��)�̏���
                              XMH.status                    IN ( '06', '04' )   -- 06:���o�ɕ񍐗L�A04:�o�ɕ񍐗L
                         -- �ړ��˗�/�w������(�A�h�I��)�Ƃ̌���
                         AND  XML.delete_flg                = 'N'               -- OFF
                         AND  XMH.mov_hdr_id                = XML.mov_hdr_id
                         -- �ړ����b�g�ڍ�(�A�h�I��)�Ƃ̌���
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '20'              -- �ړ�
                         AND  XMD.record_type_code          = '20'              -- �o�Ɏ���
                         AND  XML.mov_line_id               = XMD.mov_line_id
                         -- �ۊǏꏊ���擾
                         AND  XMH.shipped_locat_id          = XIL.inventory_location_id
                         AND  XMH.ship_to_locat_id          = XIL_TO.inventory_location_id -- 2010/03/09 H.Itou Add E_�{�ғ�_01822
                         AND  XIL.whse_code                <> XIL_TO.whse_code             -- 2010/03/09 H.Itou Add E_�{�ғ�_01822 ����q�Ɉړ��͑ΏۊO
                      --[ �S�D�ړ��o�׎��� END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- �T�D���̑��o��
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( ITC.trans_date, 'YYYYMM' )
                                                            yyyymm              --�N��
                             ,ITC.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITC.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITC.item_id                   item_id             --�i��ID
                             ,ITC.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             cargo_qty           --�ϑ����o����
                             ,ITC.trans_qty                 month_qty           --�����݌Ƀo���� �c���o�ɐ��̐ςݏグ���g�p���Č����݌ɐ������߂�
                             ,0                             rev_in_qty          --�ԕi_���Ƀo����(�d����ԕi)
                             ,0                             po_in_qty           --���Y_���Ƀo����(���)
                             ,0                             mov_in_qty          --�ړ�_���Ƀo����
                             ,0                             etc_in_qty          --���̑�_���Ƀo����
                             ,0                             oe_out_qty          --���__�o�Ƀo����(�o��)
                             ,0                             mov_out_qty         --�ړ�_�o�Ƀo����
                             ,ITC.trans_qty * -1            etc_out_qty         --���̑�_�o�Ƀo����
                        FROM
                              xxcmn_rcv_pay_mst             XRP                 --�󕥋敪�A�h�I���}�X�^
                             ,ic_adjs_jnl                   IAJ                 --OPM�݌ɒ����W���[�i��
                             ,ic_jrnl_mst                   IJM                 --OPM�W���[�i���}�X�^
                             ,ic_tran_cmp                   ITC                 --OPM�����݌Ƀg�����U�N�V����
                       WHERE
                         -- �󕥋敪�A�h�I���}�X�^�̏���
                              XRP.doc_type                  = 'ADJI'
                         AND  XRP.reason_code              <> 'X977'            --�����݌�
                         AND  XRP.reason_code              <> 'X123'            --�ړ����ђ����i�o�Ɂj
                         AND  XRP.rcv_pay_div               = '-1'              --���o
                         AND  XRP.use_div_invent            = 'Y'
                         -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITC.trans_qty                <> 0
                         AND  XRP.doc_type                  = ITC.doc_type
                         AND  XRP.reason_code               = ITC.reason_code
                         -- OPM�݌ɒ����W���[�i���Ƃ̌���
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPM�W���[�i���}�X�^�Ƃ̌���
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ �T�D���̑����� END ]--
                     --<< �e�g�����U�N�V�������猎�ԏo�ɐ����擾 END >>--
                   )  TRAN
                  ,( -- �����݌ɐ������߂�ő���Ԃ��擾�i����ȍ~�͌���݌ɐ���������Ȃ��ׂɌ����݌ɂ����܂�Ȃ��j
                     SELECT  TO_CHAR( ADD_MONTHS( TO_DATE( MAX( XSIM.invent_ym ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' )  yyyymm
                       FROM  xxinv_stc_inventory_month_stck    XSIM
                   )  MYM
           GROUP BY  TRAN.yyyymm
                    ,TRAN.whse_code
                    ,TRAN.location
                    ,TRAN.item_id
                    ,TRAN.lot_id
        )  STRN
       ,ic_whse_mst               IWM     --�q�Ƀ}�X�^
       ,xxsky_item_locations_v    ILOC    --�ۊǏꏊ�擾�p
       ,xxsky_item_mst2_v         ITEM    --�i�ږ��̎擾�p
       ,xxsky_prod_class_v        PRODC   --���i�敪�擾�p
       ,xxsky_item_class_v        ITEMC   --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v        CROWD   --�Q�R�[�h�擾�p
       ,ic_lots_mst               ILM     --���b�g�}�X�^
 WHERE
   --�q�ɖ��擾�p
        STRN.whse_code            = IWM.whse_code(+)
   --�ۊǏꏊ�擾
   AND  STRN.location             = ILOC.segment1(+)
   --�i�ږ��̎擾(SYSDATE�Ŏ擾)
   AND  STRN.item_id              = ITEM.item_id(+)
   AND  LAST_DAY( TO_DATE( STRN.yyyymm || '01', 'YYYYMMDD') ) >= ITEM.start_date_active(+)
   AND  LAST_DAY( TO_DATE( STRN.yyyymm || '01', 'YYYYMMDD') ) <= ITEM.end_date_active(+)
   --���i�敪:�h�����N�̏���  (�������ŏ������i��������X�|���X���ǂ�)
   AND  PRODC.prod_class_code     = '2'
   AND  STRN.item_id              = PRODC.item_id
   --�i�ڋ敪:���i�̏���      (�������ŏ������i��������X�|���X���ǂ�)
   AND  ITEMC.item_class_code     = '5'
   AND  STRN.item_id              = ITEMC.item_id
   --�Q�R�[�h�擾
   AND  STRN.item_id              = CROWD.item_id(+)
   --���b�g���擾
   AND  STRN.item_id              = ILM.item_id(+)
   AND  STRN.lot_id               = ILM.lot_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�h�����N�݌Ɏ���_��{_V IS 'SKYLINK�p �h�����N�݌Ɏ��сi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�Ώ۔N��                IS '�Ώ۔N��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�q�ɃR�[�h              IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�q�ɖ�                  IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ۊǏꏊ�R�[�h          IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ۊǏꏊ��              IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ۊǏꏊ����            IS '�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���i�敪                IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���i�敪��              IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�i�ڋ敪                IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�i�ڋ敪��              IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�Q�R�[�h                IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�i��                    IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�i�ږ�                  IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�i�ڗ���                IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���b�gNO                IS '���b�gNO'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�����N����              IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ŗL�L��                IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ܖ�����                IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�I���P�[�X��            IS '�I���P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�I���o����              IS '�I���o����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ϑ����݌ɃP�[�X��      IS '�ϑ����݌ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ϑ����݌Ƀo����        IS '�ϑ����݌Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�_��_�����݌ɃP�[�X��   IS '�_��_�����݌ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�_��_�����݌Ƀo����     IS '�_��_�����݌Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ԕi_���ԓ��ɃP�[�X��   IS '�ԕi_���ԓ��ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ԕi_���ԓ��Ƀo����     IS '�ԕi_���ԓ��Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���Y_���ԓ��ɃP�[�X��   IS '���Y_���ԓ��ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���Y_���ԓ��Ƀo����     IS '���Y_���ԓ��Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ړ�_���ԓ��ɃP�[�X��   IS '�ړ�_���ԓ��ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ړ�_���ԓ��Ƀo����     IS '�ړ�_���ԓ��Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���̑�_���ԓ��ɃP�[�X�� IS '���̑�_���ԓ��ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���̑�_���ԓ��Ƀo����   IS '���̑�_���ԓ��Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���__���ԏo�ɃP�[�X��   IS '���__���ԏo�ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���__���ԏo�Ƀo����     IS '���__���ԏo�Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ړ�_���ԏo�ɃP�[�X��   IS '�ړ�_���ԏo�ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.�ړ�_���ԏo�Ƀo����     IS '�ړ�_���ԏo�Ƀo����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���̑�_���ԏo�ɃP�[�X�� IS '���̑�_���ԏo�ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌Ɏ���_��{_V.���̑�_���ԏo�Ƀo����   IS '���̑�_���ԏo�Ƀo����'
/
