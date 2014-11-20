/*************************************************************************
 * 
 * View  Name      : XXSKZ_�d������_��{_V
 * Description     : XXSKZ_�d������_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�d������_��{_V
(
 ���Y�\���
,�[�i�ꏊ
,�[�i�ꏊ��
,��zNO
,�o�����i��
,�o�����i�ږ�
,�o�����i�ڗ���
,�o�������b�gNo
,�o����������
,�o�����ܖ�����
,�o�����ŗL�L��
,�o�����˗���
,�E�v
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�S�R�[�h
,�����i��
,�����i�ږ�
,�����i�ڗ���
,�������b�gNO
,����������
,�����ܖ�����
,�����ŗL�L��
,�\��敪
,�\��敪��
,�\��ԍ�
,�w��_���ѐ�
,���Ɍ�
,���Ɍ���
,�[����
,�������敪
,�������敪��
)
AS
SELECT
        WPLN.plan_start_date                                plan_start_date               --���Y�\���
       ,WPLN.location_code                                  location_code                 --�[�i�ꏊ
       ,ILCT.description                                    location_name                 --�[�i�ꏊ��
       ,WPLN.batch_no                                       batch_no                      --��zNo
       ,FITM.item_no                                        output_item_no                --�o�����i��
       ,FITM.item_name                                      output_item_name              --�o�����i�ږ�
       ,FITM.item_short_name                                output_item_s_name            --�o�����i�ڗ���
       ,NVL( DECODE( FLOT.lot_no, 'DEFAULTLOT', '0', FLOT.lot_no ), '0' )
                                                            lot_no                        --�o�����i�ڃ��b�g�ԍ�('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN FITM.lot_ctl = 1 THEN FLOT.attribute1  --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 output_manufacture_date       --�o����������
       ,CASE WHEN FITM.lot_ctl = 1 THEN FLOT.attribute3  --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 output_expiration_date        --�o�����ܖ�����
       ,CASE WHEN FITM.lot_ctl = 1 THEN FLOT.attribute2  --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 output_uniqe_sign             --�o�����ŗL�L��
       ,WPLN.output_qty                                     output_qty                    --�o�����˗���
       ,WPLN.description                                    description                   --�E�v
       ,PRODC.prod_class_code                               prod_class_code               --���i�敪
       ,PRODC.prod_class_name                               prod_class_name               --���i�敪��
       ,ITEMC.item_class_code                               item_class_code               --�i�ڋ敪
       ,ITEMC.item_class_name                               item_class_name               --�i�ڋ敪��
       ,CROWD.crowd_code                                    crowd_code                    --�Q�R�[�h
       ,MITM.item_no                                        invest_item_no                --�����i��
       ,MITM.item_name                                      invest_item_name              --�����i�ږ���
       ,MITM.item_short_name                                invest_item_s_name            --�����i�ڗ���
       ,NVL( DECODE( MLOT.lot_no, 'DEFAULTLOT', '0', MLOT.lot_no ), '0' )
                                                            lot_no                        --�������b�g�ԍ�('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN MITM.lot_ctl = 1 THEN MLOT.attribute1  --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 invest_manufacture_date       --����������
       ,CASE WHEN MITM.lot_ctl = 1 THEN MLOT.attribute3  --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 invest_expiration_date        --�����ܖ�����
       ,CASE WHEN MITM.lot_ctl = 1 THEN MLOT.attribute2  --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 invest_uniqe_sign             --�����ŗL�L��
       ,WPLN.plan_type                                      plan_type                     --�\��敪
       ,FLV01.meaning                                       plan_type_name                --�\��敪��
       ,WPLN.plan_number                                    plan_number                   --�\��ԍ�
       ,WPLN.invest_qty                                     invest_qty                    --�w��_���ѐ�
       ,WPLN.ship_from_code                                 ship_from_code                --���Ɍ�
       ,WPLN.ship_from_name                                 ship_from_name                --���Ɍ���
       ,WPLN.txns_date                                      txns_date                     --�[����
       ,WPLN.invest_ent_type                                invest_ent_type               --�������敪
       ,GOT.oprn_desc                                       invest_ent_type_name          --�������敪��
  FROM  ( --���Y�\��f�[�^�𒊏o
          -----------------------------------------------------
          -- ���Y�\��(�\��敪��'1')�{�ړ� �f�[�^�̒��o
          -----------------------------------------------------
          SELECT
                  GBH.plan_start_date                       plan_start_date               --���Y�\���
                 ,GRB.attribute9                            location_code                 --���Y�ۊǏꏊ
                 ,GBH.batch_no                              batch_no                      --��zNo(�o�b�`No)
                 ,ITP.item_id                               output_item_id                --�o�����i��ID
                 ,ITP.lot_id                                output_lot_id                 --�o�������b�gID
                 ,ITP.trans_qty                             output_qty                    --�o�����˗���
                 ,GMDF.attribute4                           description                   --�E�v
                 ,XMD.item_id                               invest_item_id                --�����i��ID
                 ,XMD.lot_id                                invest_lot_id                 --�������b�gID
                 ,XMD.plan_type                             plan_type                     --�\��敪
                 ,XMD.plan_number                           plan_number                   --�\��ԍ�
                 ,XMLD.actual_quantity                      invest_qty                    --�����w��_���ѐ�
                 ,XMRIH.shipped_locat_code                  ship_from_code                --���Ɍ�
                 ,ILCT.description                          ship_from_name                --���Ɍ���
                 ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                                            txns_date                     --�[����
                 ,GMDM.attribute8                           invest_ent_type               --�������敪
                 ,GBH.batch_id                              batch_id                      --�o�b�`ID(�������敪���擾�p)
            FROM
                  --���Y�f�[�^
                  xxcmn_gme_batch_header_arc                          GBH                 --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                 ,gmd_routings_b                            GRB                           --�H���}�X�^(���Y�f�[�^�݂̂𒊏o����ׂɌ���)
                  --���Y�f�[�^(�����i)
                 ,xxcmn_gme_material_details_arc                      GMDF                --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                 ,xxcmn_ic_tran_pnd_arc                               ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                  --���Y�f�[�^(�����i)
                 ,xxcmn_gme_material_details_arc                      GMDM                --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                 ,xxcmn_material_detail_arc                     XMD                       --���Y�����ڍׁi�A�h�I���j�o�b�N�A�b�v
                 ,xxskz_item_class_v                        ITEMC                         --�����i�̕i�ڋ敪�擾�p(���ނ����O�����)
                  --�ړ��f�[�^(�����i)
                 ,xxcmn_mov_req_instr_hdrs_arc               XMRIH                        --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                 ,xxcmn_mov_req_instr_lines_arc                 XMRIL                     --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                 ,xxcmn_mov_lot_details_arc                     XMLD                      --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                 ,xxskz_item_locations2_v                   ILCT                          --�ړ����q�ɖ��擾�p
           WHERE
             --���Y�o�b�`�w�b�_�̏���
                  GBH.batch_type                            = 0
             AND  GBH.attribute4                           <> '-1'                        --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
             AND  GBH.batch_status                          IN ( '1', '2' )               --�\��f�[�^('1:�ۗ�'�A'2:WIP')
             --�H���}�X�^�Ƃ̏���
             AND  GRB.routing_class                         NOT IN ( '61', '62', '70' )   --�i�ڐU��(70)�A���(61,62) �ȊO
             AND  GBH.routing_id                            = GRB.routing_id
             --�����ڍ׃f�[�^�y�����i�z�Ƃ̌���
             AND  GMDF.line_type                            = '1'                         --�����i
             AND  GBH.batch_id                              = GMDF.batch_id
             --�����i�̃��b�gID�擾�ׁ̈A�ۗ��݌Ƀg�����U�N�V�����f�[�^�ƌ���
             AND  ITP.doc_type                              = 'PROD'
             AND  ITP.delete_mark                           = 0
             AND  ITP.completed_ind                         = 0                           --�������Ă��Ȃ�(�˗\��)
             AND  ITP.reverse_id                            IS NULL
             AND  GMDF.material_detail_id                   = ITP.line_id
             AND  GRB.attribute9                            = ITP.location
             AND  GMDF.item_id                              = ITP.item_id
             --�����ڍ׃f�[�^�y����(�����i�̂�)�z�Ƃ̌���
             AND  GMDM.line_type                            = '-1'                        --����
             AND  NVL( GMDM.attribute5, 'N' )              <> 'Y'                         --�ō��i�ȊO(�����i)
             AND  GBH.batch_id                              = GMDM.batch_id
             AND  NVL( ITEMC.item_class_code(+), '1' )     <> '2'                         --�����i�̒��ł�'2:����'�͊܂܂Ȃ�
             AND  GMDM.item_id                              = ITEMC.item_id(+)
             --�����ڍ׃f�[�^�y����(�����i�̂�)�z�ƌ����ڍ׃A�h�I���̌���
             AND  XMD.plan_type                             = '1'                         --�\��敪(1�F�ړ�)
             AND  GMDM.batch_id                             = XMD.batch_id
             AND  GMDM.material_detail_id                   = XMD.material_detail_id
             --�����ڍ׃A�h�I���̗\��ԍ�����ړ��f�[�^���擾
             AND  XMD.plan_number                           = XMRIH.mov_num               --�����ڍ׃A�h�I��.�\��ԍ��Ɋi�[���ꂽ�ړ��ԍ��Ō���
             AND  NVL( XMRIL.delete_flg, 'N' )             <> 'Y'                         --�������׈ȊO
             AND  XMRIH.mov_hdr_id                          = XMRIL.mov_hdr_id
             AND  XMLD.document_type_code                   = '20'                        --�����^�C�v('20':�ړ�)
             AND  XMLD.record_type_code                     = DECODE( XMRIH.status        --�X�e�[�^�X��
                                                                     , '04', '20'         --'04:�o�ɕ񍐗L'   �Ȃ� '20:�o�Ɏ���'
                                                                     , '05', '30'         --'05:���ɕ񍐗L'   �Ȃ� '30:���Ɏ���'
                                                                     , '06', '30'         --'06:���o�ɕ񍐗L' �Ȃ� '30:���Ɏ���'
                                                                     , '10'               --��L�ȊO          �Ȃ� '10:�w��'
                                                                      )
             AND  XMRIL.mov_line_id                         = XMLD.mov_line_id
             AND  XMD.item_id                               = XMLD.item_id                --�����i�̕i��ID�Ō���
             AND  XMD.lot_id                                = XMLD.lot_id                 --�����i�̃��b�gID�Ō���
             --�ړ����q�ɖ��擾
             AND  XMRIH.shipped_locat_id                    = ILCT.inventory_location_id(+)
           --[ ���Y�\��(�\��敪��'1')�{�ړ� �f�[�^�̒��o  END ]
         UNION ALL
          -----------------------------------------------------
          -- ���Y�\��(�\��敪��'2')�{������� �f�[�^�̒��o
          -----------------------------------------------------
          SELECT
                  GBH.plan_start_date                       plan_start_date               --���Y�\���
                 ,GRB.attribute9                            location_code                 --���Y�ۊǏꏊ
                 ,GBH.batch_no                              batch_no                      --��zNo(�o�b�`No)
                 ,ITP.item_id                               output_item_id                --�o�����i��ID
                 ,ITP.lot_id                                output_lot_id                 --�o�������b�gID
                 ,ITP.trans_qty                             output_qty                    --�o�����˗���
                 ,GMDF.attribute4                           description                   --�E�v
                 ,XMD.item_id                               invest_item_id                --�����i��ID
                 ,XMD.lot_id                                invest_lot_id                 --�������b�gID
                 ,XMD.plan_type                             plan_type                     --�\��敪
                 ,XMD.plan_number                           plan_number                   --�\��ԍ�
                 ,PLA.quantity                              invest_qty                    --�����w��_���ѐ�
                 ,VNDR.segment1                             ship_from_code                --���Ɍ�
                 ,VNDR.vendor_name                          ship_from_name                --���Ɍ���
                 ,TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )   txns_date                     --�[����
                 ,GMDM.attribute8                           invest_ent_type               --�������敪
                 ,GBH.batch_id                              batch_id                      --�o�b�`ID(�������敪���擾�p)
            FROM
                  --���Y�f�[�^
                  xxcmn_gme_batch_header_arc                          GBH                 --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                 ,gmd_routings_b                            GRB                           --�H���}�X�^(���Y�f�[�^�݂̂𒊏o����ׂɌ���)
                  --���Y�f�[�^(�����i)
                 ,xxcmn_gme_material_details_arc                      GMDF                --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                 ,xxcmn_ic_tran_pnd_arc                               ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                  --���Y�f�[�^(�����i)
                 ,xxcmn_gme_material_details_arc                      GMDM                --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                 ,xxcmn_material_detail_arc                     XMD                       --���Y�����ڍׁi�A�h�I���j�o�b�N�A�b�v
                 ,xxskz_item_class_v                        ITEMC                         --�����i�̕i�ڋ敪�擾�p(���ނ����O�����)
                  --�����f�[�^(�����i)
                 ,po_headers_all                            PHA                           --�����w�b�_
                 ,po_lines_all                              PLA                           --��������
                 ,mtl_system_items_b                        IITM                          --INV�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,ic_item_mst_b                             OITM                          --OPM�i�ڃ}�X�^(OPM�i��ID�ϊ��p)
                 ,ic_lots_mst                               LOTS                          --���b�g�}�X�^
                 ,xxskz_vendors2_v                          VNDR                          --����於�擾�p
           WHERE
             --���Y�o�b�`�w�b�_�̏���
                  GBH.batch_type                            = 0
             AND  GBH.attribute4                           <> '-1'                        --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
             AND  GBH.batch_status                          IN ( '1', '2' )               --�\��f�[�^('1:�ۗ�'�A'2:WIP')
             --�H���}�X�^�Ƃ̏���
             AND  GRB.routing_class                         NOT IN ( '61', '62', '70' )   --�i�ڐU��(70)�A���(61,62) �ȊO
             AND  GBH.routing_id                            = GRB.routing_id
             --�����ڍ׃f�[�^�y�����i�z�Ƃ̌���
             AND  GMDF.line_type                            = '1'                         --�����i
             AND  GBH.batch_id                              = GMDF.batch_id
             --�����i�̃��b�gID�擾�ׁ̈A�ۗ��݌Ƀg�����U�N�V�����f�[�^�ƌ���
             AND  ITP.doc_type                              = 'PROD'
             AND  ITP.delete_mark                           = 0
             AND  ITP.completed_ind                         = 0                           --�������Ă��Ȃ�(�˗\��)
             AND  ITP.reverse_id                            IS NULL
             AND  GMDF.material_detail_id                   = ITP.line_id
             AND  GRB.attribute9                            = ITP.location
             AND  GMDF.item_id                              = ITP.item_id
             --�����ڍ׃f�[�^�y����(�����i�̂�)�z�Ƃ̌���
             AND  GMDM.line_type                            = '-1'                        --����
             AND  NVL( GMDM.attribute5, 'N' )              <> 'Y'                         --�ō��i�ȊO(�����i)
             AND  GBH.batch_id                              = GMDM.batch_id
             AND  NVL( ITEMC.item_class_code(+), '1' )     <> '2'                         --�����i�̒��ł�'2:����'�͊܂܂Ȃ�
             AND  GMDM.item_id                              = ITEMC.item_id(+)
             --�����ڍ׃f�[�^�y����(�����i�̂�)�z�ƌ����ڍ׃A�h�I���̌���
             AND  XMD.plan_type                             = '2'                         --�\��敪(2�F�������)
             AND  GMDM.batch_id                             = XMD.batch_id
             AND  GMDM.material_detail_id                   = XMD.material_detail_id
             --�����ڍ׃A�h�I���̗\��ԍ����甭���f�[�^���擾(�@�ƇA�܂�)
             AND  XMD.plan_number                           = PHA.segment1                --�����ڍ׃A�h�I��.�\��ԍ��Ɋi�[���ꂽ�����ԍ��Ō���
             AND  NVL( PLA.cancel_flag, 'N')               <> 'Y'                         --�������׈ȊO
             AND  PHA.po_header_id                          = PLA.po_header_id
                --�@�i��ID�̌���
             AND  PLA.item_id                               = IITM.inventory_item_id                   --����INV�i��ID��OPM�i��ID�ɕϊ�
             AND  IITM.organization_id                      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') --����INV�i��ID��OPM�i��ID�ɕϊ�
             AND  IITM.segment1                             = OITM.item_no                             --����INV�i��ID��OPM�i��ID�ɕϊ�
             AND  OITM.item_id                              = XMD.item_id                 --�����i�̕i��ID�Ō���
                --�A���b�gID�̌���
             AND  OITM.item_id                              = LOTS.item_id                --�������b�gNo�����b�gID�ɕϊ�
             AND  (    ( OITM.lot_ctl = '1' AND LOTS.lot_no = PLA.attribute1 )            --�������b�gNo�����b�gID�ɕϊ�(���b�g�Ǘ��i�Ȃ烍�b�g�ԍ��Ō���)
                    OR ( OITM.lot_ctl = '0' AND LOTS.lot_id = 0              )            --�������b�gNo�����b�gID�ɕϊ�(���b�g��Ǘ��i�Ȃ�'DEFAULTLOT')
                  )
             AND  LOTS.item_id                              = XMD.item_id                 --�����i�̕i��ID�Ō���
             AND  LOTS.lot_id                               = XMD.lot_id                  --�����i�̃��b�gID�Ō���
             --�ړ����q�ɖ��擾
             AND  PHA.vendor_id                             = VNDR.vendor_id(+)
             AND  TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )  >= VNDR.start_date_active(+)
             AND  TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )  <= VNDR.end_date_active(+)
           --[ ���Y�\��(�\��敪��'2')�{������� �f�[�^�̒��o  END ]
         UNION ALL
          -----------------------------------------------------
          -- ���Y�\��(�\��敪��'3:�݌ɗL��') �f�[�^�̒��o
          -----------------------------------------------------
          SELECT
                  GBH.plan_start_date                       plan_start_date               --���Y�\���
                 ,GRB.attribute9                            location_code                 --���Y�ۊǏꏊ
                 ,GBH.batch_no                              batch_no                      --��zNo(�o�b�`No)
                 ,ITP.item_id                               output_item_id                --�o�����i��ID
                 ,ITP.lot_id                                output_lot_id                 --�o�������b�gID
                 ,ITP.trans_qty                             output_qty                    --�o�����˗���
                 ,GMDF.attribute4                           description                   --�E�v
                 ,XMD.item_id                               invest_item_id                --�����i��ID
                 ,XMD.lot_id                                invest_lot_id                 --�������b�gID
                 ,XMD.plan_type                             plan_type                     --�\��敪
                 ,XMD.plan_number                           plan_number                   --�\��ԍ�
                 ,NVL( XMD.invested_qty, 0 ) - NVL( XMD.return_qty, 0 )
                                                            invest_qty                    --�����w��_���ѐ�
                 ,NULL                                      ship_from_code                --���Ɍ�
                 ,NULL                                      ship_from_name                --���Ɍ���
                 ,NULL                                      txns_date                     --�[����
                 ,GMDM.attribute8                           invest_ent_type               --�������敪
                 ,GBH.batch_id                              batch_id                      --�o�b�`ID(�������敪���擾�p)
            FROM
                  --���Y�f�[�^
                  xxcmn_gme_batch_header_arc                          GBH                 --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                 ,gmd_routings_b                            GRB                           --�H���}�X�^(���Y�f�[�^�݂̂𒊏o����ׂɌ���)
                  --���Y�f�[�^(�����i)
                 ,xxcmn_gme_material_details_arc                      GMDF                --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                 ,xxcmn_ic_tran_pnd_arc                               ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                  --���Y�f�[�^(�����i)
                 ,xxcmn_gme_material_details_arc                      GMDM                --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                 ,xxcmn_material_detail_arc                     XMD                       --���Y�����ڍׁi�A�h�I���j�o�b�N�A�b�v
                 ,xxskz_item_class_v                        ITEMC                         --�����i�̕i�ڋ敪�擾�p(���ނ����O�����)
           WHERE
             --���Y�o�b�`�w�b�_�̏���
                  GBH.batch_type                            = 0
             AND  GBH.attribute4                           <> '-1'                        --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
             AND  GBH.batch_status                          IN ( '1', '2' )               --�\��f�[�^('1:�ۗ�'�A'2:WIP')
             --�H���}�X�^�Ƃ̏���
             AND  GRB.routing_class                         NOT IN ( '61', '62', '70' )   --�i�ڐU��(70)�A���(61,62) �ȊO
             AND  GBH.routing_id                            = GRB.routing_id
             --�����ڍ׃f�[�^�y�����i�z�Ƃ̌���
             AND  GMDF.line_type                            = '1'                         --�����i
             AND  GBH.batch_id                              = GMDF.batch_id
             --�����i�̃��b�gID�擾�ׁ̈A�ۗ��݌Ƀg�����U�N�V�����f�[�^�ƌ���
             AND  ITP.doc_type                              = 'PROD'
             AND  ITP.delete_mark                           = 0
             AND  ITP.completed_ind                         = 0                           --�������Ă��Ȃ�(�˗\��)
             AND  ITP.reverse_id                            IS NULL
             AND  GMDF.material_detail_id                   = ITP.line_id
             AND  GRB.attribute9                            = ITP.location
             AND  GMDF.item_id                              = ITP.item_id
             --�����ڍ׃f�[�^�y����(�����i�̂�)�z�Ƃ̌���
             AND  GMDM.line_type                            = '-1'                        --����
             AND  NVL( GMDM.attribute5, 'N' )              <> 'Y'                         --�ō��i�ȊO(�����i)
             AND  GBH.batch_id                              = GMDM.batch_id
             AND  NVL( ITEMC.item_class_code(+), '1' )     <> '2'                         --�����i�̒��ł�'2:����'�͊܂܂Ȃ�
             AND  GMDM.item_id                              = ITEMC.item_id(+)
             --�����ڍ׃f�[�^�y����(�����i�̂�)�z�ƌ����ڍ׃A�h�I���̌���
             AND  XMD.plan_type                             = '3'                         --�\��敪(3�F�݌�)
             AND  GMDM.batch_id                             = XMD.batch_id
             AND  GMDM.material_detail_id                   = XMD.material_detail_id
           --[ ���Y�\��(�\��敪��'3:�݌ɗL��') �f�[�^�̒��o  END ]
        )                               WPLN                --���Y�\��f�[�^
       ,xxskz_item_locations_v          ILCT                --�[�i�ꏊ���擾�p
       ,xxskz_item_mst2_v               FITM                --�o�����i�ږ��擾�p
       ,ic_lots_mst                     FLOT                --�o�����i�ڃ��b�g���擾�p
       ,xxskz_item_mst2_v               MITM                --�����i�ږ��擾�p
       ,ic_lots_mst                     MLOT                --�����i�ڃ��b�g���擾�p
       ,xxskz_prod_class_v              PRODC               --�����i�ڏ��i�敪�擾�p
       ,xxskz_item_class_v              ITEMC               --�����i�ڕi�ڋ敪�擾�p
       ,xxskz_crowd_code_v              CROWD               --�����i�ڌQ�R�[�h�擾�p
       ,gmd_operations_tl               GOT                 --�H���}�X�^(�������敪���擾�p)
       ,xxcmn_gme_batch_steps_arc                 GBS       --���Y�o�b�`�X�e�b�v�i�W���j�o�b�N�A�b�v
       ,fnd_lookup_values               FLV01               --�\��敪���擾�p
 WHERE
   --�[�i�ꏊ���擾
        WPLN.location_code              = ILCT.segment1(+)
   --�o�����i�ڏ��擾
   AND  WPLN.output_item_id             = FITM.item_id(+)
   AND  WPLN.plan_start_date           >= FITM.start_date_active(+)
   AND  WPLN.plan_start_date           <= FITM.end_date_active(+)
   --�o�����i�ڃ��b�g���擾
   AND  WPLN.output_item_id             = FLOT.item_id(+)
   AND  WPLN.output_lot_id              = FLOT.lot_id(+)
   --�����i�ڏ��擾
   AND  WPLN.invest_item_id             = MITM.item_id(+)
   AND  WPLN.plan_start_date           >= MITM.start_date_active(+)
   AND  WPLN.plan_start_date           <= MITM.end_date_active(+)
   --�����i�ڃ��b�g���擾
   AND  WPLN.invest_item_id             = MLOT.item_id(+)
   AND  WPLN.invest_lot_id              = MLOT.lot_id(+)
   --�����i�ڃJ�e�S�����擾
   AND  WPLN.invest_item_id             = PRODC.item_id(+)
   AND  WPLN.invest_item_id             = ITEMC.item_id(+)
   AND  WPLN.invest_item_id             = CROWD.item_id(+)
   --�������敪���擾
   AND  WPLN.batch_id                   = GBS.batch_id(+)
   AND  WPLN.invest_ent_type            = GBS.batchstep_no(+)
   AND  GOT.language(+)                 = 'JA'
   AND  GBS.oprn_id                     = GOT.oprn_id(+)
   --���b�g�\��敪��
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWIP_PLAN_TYPE'
   AND  FLV01.lookup_code(+)            = WPLN.plan_type
/
COMMENT ON TABLE APPS.XXSKZ_�d������_��{_V IS 'SKYLINK�p�d�����׊�{VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.���Y�\���     IS '���Y�\���'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�[�i�ꏊ       IS '�[�i�ꏊ'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�[�i�ꏊ��     IS '�[�i�ꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.��zNO         IS '��zNO'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o�����i��     IS '�o�����i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o�����i�ږ�   IS '�o�����i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o�����i�ڗ��� IS '�o�����i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o�������b�gNo IS '�o�������b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o����������   IS '�o����������'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o�����ܖ����� IS '�o�����ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o�����ŗL�L�� IS '�o�����ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�o�����˗���   IS '�o�����˗���'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�E�v           IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.���i�敪       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.���i�敪��     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�i�ڋ敪       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�i�ڋ敪��     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�S�R�[�h       IS '�S�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�����i��       IS '�����i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�����i�ږ�     IS '�����i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�����i�ڗ���   IS '�����i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�������b�gNo   IS '�������b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.����������     IS '����������'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�����ܖ�����   IS '�����ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�����ŗL�L��   IS '�����ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�\��敪       IS '�\��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�\��敪��     IS '�\��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�\��ԍ�       IS '�\��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�w��_���ѐ�    IS '�w��_���ѐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.���Ɍ�         IS '���Ɍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.���Ɍ���       IS '���Ɍ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�[����         IS '�[����'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�������敪     IS '�������敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�d������_��{_V.�������敪��   IS '�������敪��'
/
