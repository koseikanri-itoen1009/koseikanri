CREATE OR REPLACE VIEW APPS.XXSKY_�h�����N�݌ɏ��_��{_V
(
 �q�ɃR�[�h
,�q�ɖ�
,��\�q�ɃR�[�h
,��\�q�ɖ�
,��\�q�ɗ���
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
,���ɓ�
,���Ɍ��R�[�h
,���Ɍ���
,�݌ɒP��
,������P�[�X�݌ɐ�
,������o���݌ɐ�
,������P�[�X�o�Ɏw����
,������o���o�Ɏw����
,�Ǖi�P�[�X�݌ɐ�
,�Ǖi�o���݌ɐ�
,�Ǖi�P�[�X�o�Ɏw����
,�Ǖi�o���o�Ɏw����
,�����t�Ǖi�P�[�X�݌ɐ�
,�����t�Ǖi�o���݌ɐ�
,�����t�Ǖi�P�[�X�o�Ɏw����
,�����t�Ǖi�o���o�Ɏw����
,�s�Ǖi�P�[�X�݌ɐ�
,�s�Ǖi�o���݌ɐ�
,�s�Ǖi�P�[�X�o�Ɏw����
,�s�Ǖi�o���o�Ɏw����
-- ***** 2009/09/24 #1634 S *****
,�ۗ��P�[�X�݌ɐ�
,�ۗ��o���݌ɐ�
,�ۗ��P�[�X�o�Ɏw����
,�ۗ��o���o�Ɏw����
-- ***** 2009/09/24 #1634 E *****
)
AS
SELECT
         STRN.whse_code                                     whse_code           --�q�ɃR�[�h
        ,IWM.whse_name                                      whse_name           --�q�ɖ�
         --��\�q�ɃR�[�h
        ,CASE WHEN ILOC.frequent_whse = 'ZZZZ' THEN         --��\�q�ɃR�[�h��'ZZZZ'�Ȃ�i�ڕʑ�\�q�ɃR�[�h
                NVL( XFIL.frq_item_location_code, STRN.location )
              ELSE                                          --��L�ȊO�͑�\�q�ɃR�[�h
                NVL( ILOC.frequent_whse         , STRN.location )
         END                                                frequent_whse       --��\�q�ɃR�[�h�i��\�q�ɂ̓o�^�������f�[�^�͎����̕ۊǏꏊ�R�[�h�j
         --��\�q�ɖ�
        ,CASE WHEN ILOC.frequent_whse = 'ZZZZ' THEN         --��\�q�ɃR�[�h��'ZZZZ'�Ȃ�i�ڕʑ�\�q�ɖ�
                DECODE( XFIL.frq_item_location_code, NULL, ILOC.description, FQLOC.description )
              ELSE                                          --��L�ȊO�͑�\�q�ɖ�
                DECODE( ILOC.frequent_whse         , NULL, ILOC.description, FLOC.description  )
         END                                                fq_whse_name        --��\�q�ɖ��i��\�q�ɂ̓o�^�������f�[�^�͎����̕ۊǏꏊ���j
         --��\�q�ɗ���
        ,CASE WHEN ILOC.frequent_whse = 'ZZZZ' THEN         --��\�q�ɃR�[�h��'ZZZZ'�Ȃ�i�ڕʑ�\�q�ɗ���
                DECODE( XFIL.frq_item_location_code, NULL, ILOC.short_name, FQLOC.short_name )
              ELSE                                          --��L�ȊO�͑�\�q�ɗ���
                DECODE( ILOC.frequent_whse         , NULL, ILOC.short_name, FLOC.short_name  )
         END                                                fq_whse_s_name      --��\�q�ɗ��́i��\�q�ɂ̓o�^�������f�[�^�͎����̕ۊǏꏊ���́j
        ,STRN.location                                      location            --�ۊǏꏊ�R�[�h
        ,ILOC.description                                   loct_name           --�ۊǏꏊ��
        ,ILOC.short_name                                    loct_s_name         --�ۊǏꏊ����
        ,PRODC.prod_class_code                              prod_class_code     --���i�敪
        ,PRODC.prod_class_name                              prod_class_name     --���i�敪��
        ,ITEMC.item_class_code                              item_class_code     --�i�ڋ敪
        ,ITEMC.item_class_name                              item_class_name     --�i�ڋ敪��
        ,CROWD.crowd_code                                   crowd_code          --�Q�R�[�h
        ,ITEM.item_no                                       item_code           --�i��
        ,ITEM.item_name                                     item_name           --�i�ږ�
        ,ITEM.item_short_name                               item_s_name         --�i�ڗ���
        ,ILM.lot_no                                         lot_no              --���b�gNo
        ,ILM.attribute1                                     lot_date            --�����N����
        ,ILM.attribute2                                     lot_sign            --�ŗL�L��
        ,ILM.attribute3                                     best_bfr_date       --�ܖ�����
        ,STRN.in_whse_date                                  in_whse_date        --���ɓ�
        ,ILM.attribute8                                     vendor_code         --���Ɍ��R�[�h
        ,VNDR.vendor_name                                   vendor_name         --���Ɍ���
        ,TO_NUMBER( ILM.attribute7 )                        inv_amt             --�݌ɒP��
         --������
        ,NVL( TRUNC( STRN.njdg_qty     / ITEM.num_of_cases ), 0 )
                                                            njdg_case_qty       --������P�[�X�݌ɐ�
        ,NVL( STRN.njdg_qty    , 0 )                        njdg_qty            --������o���݌ɐ�
        ,NVL( TRUNC( STRN.njdg_out_qty / ITEM.num_of_cases ), 0 )
                                                            njdg_out_case_qty   --������P�[�X�o�Ɏw����
        ,NVL( STRN.njdg_out_qty, 0 )                        njdg_out_qty        --������o���o�Ɏw����
         --�Ǖi
        ,NVL( TRUNC( STRN.good_qty     / ITEM.num_of_cases ), 0 )
                                                            good_case_qty       --�Ǖi�P�[�X�݌ɐ�
        ,NVL( STRN.good_qty    , 0 )                        good_qty            --�Ǖi�o���݌ɐ�
        ,NVL( TRUNC( STRN.good_out_qty / ITEM.num_of_cases ), 0 )
                                                            good_out_case_qty   --�Ǖi�P�[�X�o�Ɏw����
        ,NVL( STRN.good_out_qty, 0 )                        good_out_qty        --�Ǖi�o���o�Ɏw����
         --�����t�Ǖi
        ,NVL( TRUNC( STRN.term_qty     / ITEM.num_of_cases ), 0 )
                                                            term_case_qty       --�����t�Ǖi�P�[�X�݌ɐ�
        ,NVL( STRN.term_qty    , 0 )                        term_qty            --�����t�Ǖi�o���݌ɐ�
        ,NVL( TRUNC( STRN.term_out_qty / ITEM.num_of_cases ), 0 )
                                                            term_out_case_qty   --�����t�Ǖi�P�[�X�o�Ɏw����
        ,NVL( STRN.term_out_qty, 0 )                        term_out_qty        --�����t�Ǖi�o���o�Ɏw����
         --�s�Ǖi
        ,NVL( TRUNC( STRN.ng_qty       / ITEM.num_of_cases ), 0 )
                                                            ng_case_qty         --�s�Ǖi�P�[�X�݌ɐ�
        ,NVL( STRN.ng_qty      , 0 )                        ng_qty              --�s�Ǖi�o���݌ɐ�
        ,NVL( TRUNC( STRN.ng_out_qty   / ITEM.num_of_cases ), 0 )
                                                            ng_out_case_qty     --�s�Ǖi�P�[�X�o�Ɏw����
        ,NVL( STRN.ng_out_qty  , 0 )                        ng_out_qty          --�s�Ǖi�o���o�Ɏw����
-- ***** 2009/09/24 #1634 S *****
         --�ۗ�
        ,NVL( TRUNC( STRN.hold_qty       / ITEM.num_of_cases ), 0 )
                                                            hold_case_qty       --�ۗ��P�[�X�݌ɐ�
        ,NVL( STRN.hold_qty      , 0 )                      hold_qty            --�ۗ��o���݌ɐ�
        ,NVL( TRUNC( STRN.hold_out_qty   / ITEM.num_of_cases ), 0 )
                                                            hold_out_case_qty   --�ۗ��P�[�X�o�Ɏw����
        ,NVL( STRN.hold_out_qty  , 0 )                      hold_out_qty        --�ۗ��o���o�Ɏw����
-- ***** 2009/09/24 #1634 E *****
  FROM
        (
          --************************************************************************
          -- ���݌Ɂ{�o�Ɏw�������o�͂��郌�R�[�h���쐬  Start
          --************************************************************************
           --�q�ɃR�[�h�A�ۊǏꏊ�R�[�h�A�i��ID�A���b�gID�P�ʂŏW�v
           SELECT
                   TRAN.whse_code                           whse_code           --�q�ɃR�[�h
                  ,TRAN.location                            location            --�ۊǏꏊ�R�[�h
                  ,NULL                                     in_whse_date        --���ɓ�
                  ,TRAN.item_id                             item_id             --�i��ID
                  ,TRAN.lot_id                              lot_id              --���b�gID
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '10' THEN TRAN.onhand_qty END )  njdg_qty      --������o���݌ɐ�
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '10' THEN TRAN.out_qty    END )  njdg_out_qty  --������o���o�Ɏw����
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '50' THEN TRAN.onhand_qty END )  good_qty      --�Ǖi�o���݌ɐ�
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '50' THEN TRAN.out_qty    END )  good_out_qty  --�Ǖi�o���o�Ɏw����
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '30' THEN TRAN.onhand_qty END )  term_qty      --�����t�Ǖi�o���݌ɐ�
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '30' THEN TRAN.out_qty    END )  term_out_qty  --�����t�Ǖi�o���o�Ɏw����
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '60' THEN TRAN.onhand_qty END )  ng_qty        --�s�Ǖi�o���݌ɐ�
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '60' THEN TRAN.out_qty    END )  ng_out_qty    --�s�Ǖi�o���o�Ɏw����
-- ***** 2009/09/24 #1634 S *****
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '70' THEN TRAN.onhand_qty END )  hold_qty      --�ۗ��i�o���݌ɐ�
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '70' THEN TRAN.out_qty    END )  hold_out_qty  --�ۗ��i�o���o�Ɏw����
-- ***** 2009/09/24 #1634 E *****
             FROM
                   (
                    --======================================================================
                    -- ���݌ɐ����莝���݌ɂƊe�g�����U�N�V��������擾
                    --  �P�D�莝���݌�
                    --  �Q�D�ړ����Ɏ���(�o�ɕ񍐑҂�)
                    --  �R�D�ړ��o�Ɏ���(���ɕ񍐑҂�)
                    --  �S�D�ړ����Ɏ���(���ђ���)
                    --  �T�D�ړ��o�Ɏ���(���ђ���)
                    --  �U�D�o�ׁE�q�֕ԕi����(EBS���ьv��҂�)
                    --  �V�D�x������(EBS���ьv��҂�)
                    --     �� �Q�`�T��EBS�莝���݌ɂɔ��f����Ă��Ȃ����уf�[�^
                    --======================================================================
                      -------------------------------------------------------------
                      -- �P�D�莝���݌�
                      -------------------------------------------------------------
                      SELECT
                              ILI.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ILI.location                  location            --�ۊǏꏊ�R�[�h
                             ,ILI.item_id                   item_id             --�i��ID
                             ,ILI.lot_id                    lot_id              --���b�gID
                             ,ILI.loct_onhand               onhand_qty          --�o���݌ɐ�
                             ,0                             out_qty             --�o�׎w���o����
                        FROM
                              ic_loct_inv                   ILI                 --OPM�莝������
                      --[ �P�D�莝���݌�  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �Q�D�ړ����Ɏ���(�o�ɕ񍐑҂�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,MLD.actual_quantity           onhand_qty          --�o���݌ɐ�
                             ,0                             out_qty             --�o�׎w���o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v�� �� EBS�݌ɖ����f
                         AND  MRIH.status                   IN ( '05', '06' )   --05:���ɕ񍐗L�A06:���o�ɕ񍐗L
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '30'              --���Ɏ���
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --���ɐ�ۊǏꏊ���擾
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ �Q�D�ړ����Ɏ���(���o�ɕ񍐑҂�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �R�D�ړ��o�Ɏ���(���ɕ񍐑҂�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,MLD.actual_quantity * -1      onhand_qty          --�o���݌ɐ�
                             ,0                             out_qty             --�o�׎w���o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v�� �� EBS�݌ɖ����f
                         AND  MRIH.status                   IN ( '04', '06' )   --04:�o�ɕ񍐗L�A06:���o�ɕ񍐗L
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '20'              --�o�Ɏ���
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --���ɐ�ۊǏꏊ���擾
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ �R�D�ړ��o�Ɏ���(���o�ɕ񍐑҂�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �S�D�ړ����Ɏ���(���ђ���)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                                                            onhand_qty          --�o���݌ɐ�
                             ,0                             out_qty             --�o�׎w���o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              MRIH.comp_actual_flg          = 'Y'               --���ьv�� �� EBS�݌ɔ��f��
                         AND  MRIH.correct_actual_flg       = 'Y'               --���ђ�����
                         AND  MRIH.status                   = '06'              --06:���o�ɕ񍐗L
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '30'              --���Ɏ���
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --���ɐ�ۊǏꏊ���擾
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ �S�D�ړ����Ɏ���(���ђ���)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �T�D�ړ��o�Ɏ���(���ђ���)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) ) * -1
                                                            onhand_qty          --�o���݌ɐ�
                             ,0                             out_qty             --�o�׎w���o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              MRIH.comp_actual_flg          = 'Y'               --���ьv�� �� EBS�݌ɖ����f��
                         AND  MRIH.correct_actual_flg       = 'Y'               --���ђ�����
                         AND  MRIH.status                   = '06'              --06:���o�ɕ񍐗L
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '20'              --�o�Ɏ���
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --���ɐ�ۊǏꏊ���擾
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ �T�D�ړ��o�Ɏ���(���ђ���)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �U�D�o�ׁE�q�֕ԕi����(EBS���ьv��҂�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            onhand_qty          --�o���݌ɐ�
                             ,0                             out_qty             --�o�׎w���o����
                        FROM
                              xxwsh_order_headers_all       OHA                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         OLA                 --�󒍖���
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�󒍃w�b�_�̏���
                              OHA.req_status                = '04'              --���ьv���
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --���і��v�� �� EBS�݌ɖ����f
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���(�o�׃f�[�^�𒊏o)
                         AND  OTTA.attribute1               IN ( '1', '3' )     --�o�׈˗��A�q�֕ԕi
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '10'              --�o�׈˗�
                         AND  MLD.record_type_code          = '20'              --�o�Ɏ���
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ �U�D�o�ׁE�q�֕ԕi����(���ו񍐑҂�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �V�D�x������(EBS���ьv��҂�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            onhand_qty          --�o���݌ɐ�
                             ,0                             out_qty             --�o�׎w���o����
                        FROM
                              xxwsh_order_headers_all       OHA                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         OLA                 --�󒍖���
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�󒍃w�b�_�̏���
                              OHA.req_status                = '08'              --���ьv���
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --���і��v�� �� EBS�݌ɖ����f
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���(�o�׃f�[�^�𒊏o)
                         AND  OTTA.attribute1               = '2'               --�x���w��
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '30'              --�x���w��
                         AND  MLD.record_type_code          = '20'              --�o�Ɏ���
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ �V�D�x������(���ו񍐑҂�)  End ]--
                    --<< ���݌ɐ����莝���݌ɂƊe�g�����U�N�V��������擾  END >>--
                    UNION ALL
                    --======================================================================
                    -- �o�Ɏw�������e�g�����U�N�V��������擾
                    --  �P�D�ړ��o�ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                    --  �Q�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)
                    --  �R�D�󒍏o�ח\��
                    --  �S�D�L���o�ח\��
                    --======================================================================
                      -------------------------------------------------------------
                      -- �P�D�ړ��o�ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             onhand_qty          --�o���݌ɐ�
                             ,MLD.actual_quantity           out_qty             --�o�׎w���o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_(�A�h�I��)
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w������(�A�h�I��)
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�(�A�h�I��)
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v��
                         AND  MRIH.status                   IN ( '02', '03' )   --02:�˗��ρA03:������
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '10'              --�w��
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ �P�D�ړ��o�ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �Q�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             onhand_qty          --�o���݌ɐ�
                             ,MLD.actual_quantity           out_qty             --�o�׎w���o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_(�A�h�I��)
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w������(�A�h�I��)
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�(�A�h�I��)
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              MRIH.mov_type                 = '1'               --�ϑ�����
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v��
                         AND  MRIH.status                   = '05'              --05:���ɕ񍐗L
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '30'              --���Ɏ���
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ �Q�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �R�D�󒍏o�ח\��
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             onhand_qty          --�o���݌ɐ�
                             ,MLD.actual_quantity           out_qty             --�o�׎w���o����
                        FROM
                              xxwsh_order_headers_all       OHA                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         OLA                 --�󒍖���
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�󒍃w�b�_�̏���
                              OHA.req_status                = '03'              --���ߍ�
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --���і��v��
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���(�o�׃f�[�^�𒊏o)
                         AND  OTTA.attribute1               = '1'               --�o�׈˗�
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '10'              --�o�׈˗�
                         AND  MLD.record_type_code          = '10'              --�w��
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ �R�D�󒍏o�ח\��  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �S�D�L���o�ח\��
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             onhand_qty          --�o���݌ɐ�
                             ,MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                            out_qty             --�o�׎w���o����
                        FROM
                              xxwsh_order_headers_all       OHA                 --�󒍃w�b�_
                             ,xxwsh_order_lines_all         OLA                 --�󒍖���
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�󒍃w�b�_�̏���
                              OHA.req_status                = '07'              --��̍�
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --���і��v��
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --�󒍃^�C�v�}�X�^�Ƃ̌���(�o�׃f�[�^�𒊏o)
                         AND  OTTA.attribute1               = '2'               --�x���w��
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --�󒍖��ׂƂ̌���
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '30'              --�x���w��
                         AND  MLD.record_type_code          = '10'              --�w��
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ �S�D�L���o�ח\��  End ]--
                    --<< �o�Ɏw�������e�g�����U�N�V��������擾  END >>--
                   )  TRAN
                  ,ic_lots_mst                              ILM                 --OPM���b�g�}�X�^
            WHERE
              --OPM���b�g�}�X�^�Ƃ̌���
                   TRAN.item_id                             = ILM.item_id
              AND  TRAN.lot_id                              = ILM.lot_id
           GROUP BY TRAN.whse_code    --�q�ɃR�[�h
                   ,TRAN.location     --�ۊǏꏊ�R�[�h
                   ,TRAN.item_id      --�i��ID
                   ,TRAN.lot_id       --���b�gID
          -- �y ���݌Ɂ{�o�Ɏw�������o�͂��郌�R�[�h���쐬  End �z --
--
         UNION ALL
          --************************************************************************
          -- ���ɗ\�萔���o�͂��郌�R�[�h���쐬  Start
          --************************************************************************
           SELECT
                   ITRAN.whse_code                          whse_code           --�q�ɃR�[�h
                  ,ITRAN.location                           location            --�ۊǏꏊ�R�[�h
                  ,ITRAN.in_whse_date                       in_whse_date        --���ɓ�
                  ,ITRAN.item_id                            item_id             --�i��ID
                  ,ITRAN.lot_id                             lot_id              --���b�gID
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '10' THEN ITRAN.in_qty END )  njdg_qty      --������o���݌ɐ�
                  ,0                                                                          njdg_out_qty  --������o���o�Ɏw����
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '50' THEN ITRAN.in_qty END )  good_qty      --�Ǖi�o���݌ɐ�
                  ,0                                                                          good_out_qty  --�Ǖi�o���o�Ɏw����
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '30' THEN ITRAN.in_qty END )  term_qty      --�����t�Ǖi�o���݌ɐ�
                  ,0                                                                          term_out_qty  --�����t�Ǖi�o���o�Ɏw����
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '60' THEN ITRAN.in_qty END )  ng_qty        --�s�Ǖi�o���݌ɐ�
                  ,0                                                                          ng_out_qty    --�s�Ǖi�o���o�Ɏw����
-- ***** 2009/09/24 #1634 S *****
                  ,SUM( CASE WHEN NVL( ILM.attribute23,'10' ) = '70' THEN ITRAN.in_qty END )  hold_qty      --�ۗ��o���݌ɐ�
                  ,0                                                                          hold_out_qty  --�ۗ��o���o�Ɏw����
-- ***** 2009/09/24 #1634 E *****
             FROM
                  (
                    --======================================================================
                    -- ������ȍ~�̓��ɗ\�萔���e�g�����U�N�V��������擾
                    --  �P�D��������\��
                    --  �Q�D�ړ����ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                    --  �R�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)
                    --======================================================================
                      -------------------------------------------------------------
                      -- �P�D��������\��
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )
                                                            in_whse_date        --���ɓ�
                             ,IIM.item_id                   item_id             --�i��ID
                             ,ILM.lot_id                    lot_id              --���b�gID
                             ,PLA.quantity                  in_qty              --���ɗ\��o����
                        FROM  po_headers_all                PHA                 --�����w�b�_
                             ,po_lines_all                  PLA                 --��������
                             ,xxsky_item_locations_v        XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,ic_item_mst_b                 IIM                 --OPM�i�ڃ}�X�^(OPM�i��ID�擾�p)
                             ,mtl_system_items_b            MSI                 --INV�i�ڃ}�X�^(OPM�i��ID�擾�p)
                             ,ic_lots_mst                   ILM                 --OPM���b�g�}�X�^(���b�gID�擾�p)
                       WHERE
                         --�����w�b�_�̏���
                              PHA.attribute1                IN ( '20', '25' )   --20:�����쐬�ρA25:�������
                         --�������ׂƂ̌���
                         AND  NVL( PLA.attribute13, 'N' )  <> 'Y'               --������
                         AND  NVL( PLA.cancel_flag, 'N' )  <> 'Y'
                         AND  PHA.po_header_id              = PLA.po_header_id
                         --OPM�i��ID�擾
                         AND  PLA.item_id                   = MSI.inventory_item_id
                         AND  MSI.organization_id           = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
                         AND  MSI.segment1                  = IIM.item_no
                         --OPM���b�gID�擾
                         AND  IIM.item_id                   = ILM.item_id
                         AND (   ( IIM.lot_ctl = 1 AND PLA.attribute1 = ILM.lot_no )  --���b�g�Ǘ��i
                              OR ( IIM.lot_ctl = 0 AND ILM.lot_id     = 0          )  --�񃍃b�g�Ǘ��i
                             )
                         --���ɐ�ۊǏꏊ���擾
                         AND  PHA.attribute5                = XILV.segment1
                      --[ �P�D��������\��  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �Q�D�ړ����ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MRIH.schedule_arrival_date    in_whse_date        --���ɓ�
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,MLD.actual_quantity           in_qty              --���ɗ\��o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_(�A�h�I��)
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w������(�A�h�I��)
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�(�A�h�I��)
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v��
                         AND  MRIH.status                   IN ( '02', '03' )   --02:�˗��ρA03:������
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '10'              --�w��
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --���ɐ�ۊǏꏊ���擾
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ �Q�D�ړ����ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �R�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MRIH.schedule_arrival_date    in_whse_date        --���ɓ�
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,MLD.actual_quantity           in_qty              --���ɗ\��o����
                        FROM
                              xxinv_mov_req_instr_headers   MRIH                --�ړ��˗�/�w���w�b�_(�A�h�I��)
                             ,xxinv_mov_req_instr_lines     MRIL                --�ړ��˗�/�w������(�A�h�I��)
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�(�A�h�I��)
                             ,xxsky_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              MRIH.mov_type                 = '1'               --�ϑ�����
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v��
                         AND  MRIH.status                   = '04'              --04:�o�ɕ񍐗L
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '20'              --�o�Ɏ���
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --���ɐ�ۊǏꏊ���擾
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ �R�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)  End ]--
                   )  ITRAN
                  ,ic_lots_mst                              ILM                 --OPM���b�g�}�X�^
            WHERE
              --OPM���b�g�}�X�^�Ƃ̌���
                   ITRAN.item_id                            = ILM.item_id
              AND  ITRAN.lot_id                             = ILM.lot_id
           GROUP BY ITRAN.whse_code     --�q�ɃR�[�h
                   ,ITRAN.location      --�ۊǏꏊ�R�[�h
                   ,ITRAN.in_whse_date  --���ɓ�
                   ,ITRAN.item_id       --�i��ID
                   ,ITRAN.lot_id        --���b�gID
          -- �y ���ɗ\�萔���o�͂��郌�R�[�h���쐬  End �z --
        )  STRN
       ,ic_whse_mst                     IWM     --�q�Ƀ}�X�^
       ,xxsky_item_locations_v          ILOC    --�ۊǏꏊ�擾�p
       ,xxsky_item_mst_v                ITEM    --�i�ږ��̎擾�p(���ݓ��t�Ŏ擾)
       ,xxsky_prod_class_v              PRODC   --���i�敪�擾�p
       ,xxsky_item_class_v              ITEMC   --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v              CROWD   --�Q�R�[�h�擾�p
       ,ic_lots_mst                     ILM     --���b�g�}�X�^
       ,xxsky_vendors_v                 VNDR    --����於�擾�p
       ,xxsky_item_locations_v          FLOC    --��\�q�ɖ��擾�p
       ,xxwsh_frq_item_locations        XFIL    --�q�ɕi�ڃA�h�I��(�i�ڕʑ�\�q�Ɏ擾�p)
       ,xxsky_item_locations_v          FQLOC   --�i�ڕʑ�\�q�ɖ��擾�p
 WHERE
   --�q�ɖ��擾�p
        STRN.whse_code                  = IWM.whse_code(+)
   --�ۊǏꏊ�i�{��\�q�ɃR�[�h�j�擾
   AND  STRN.location                   = ILOC.segment1(+)
   --��\�q�ɖ��擾
   AND  ILOC.frequent_whse              = FLOC.segment1(+)
   --�i�ڕʑ�\�q�ɃR�[�h�擾
   AND  STRN.location                   = XFIL.item_location_code(+)
   AND  STRN.item_id                    = XFIL.item_id(+)
   --�i�ڕʑ�\�q�ɖ��擾
   AND  XFIL.frq_item_location_code     = FQLOC.segment1(+)
   --�i�ږ��̎擾(���ݓ��t�Ŏ擾)
   AND  STRN.item_id                    = ITEM.item_id(+)
   --���i�敪:�h�����N�̏���  (�������ŏ������i��������X�|���X���ǂ�)
   AND  PRODC.prod_class_code           = '2'
   AND  STRN.item_id                    = PRODC.item_id
   --�i�ڋ敪:���i�̏���      (�������ŏ������i��������X�|���X���ǂ�)
   AND  ITEMC.item_class_code           = '5'
   AND  STRN.item_id                    = ITEMC.item_id
   --�Q�R�[�h�擾
   AND  STRN.item_id                    = CROWD.item_id(+)
   --���b�g���擾
   AND  STRN.item_id                    = ILM.item_id(+)
   AND  STRN.lot_id                     = ILM.lot_id(+)
   --����於�擾
   AND  ILM.attribute8                  = VNDR.segment1(+)
/
COMMENT ON TABLE APPS.XXSKY_�h�����N�݌ɏ��_��{_V IS 'SKYLINK�p �h�����N�݌ɏ��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�q�ɃR�[�h                 IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�q�ɖ�                     IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.��\�q�ɃR�[�h             IS '��\�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.��\�q�ɖ�                 IS '��\�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.��\�q�ɗ���               IS '��\�q�ɗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ۊǏꏊ�R�[�h             IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ۊǏꏊ��                 IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ۊǏꏊ����               IS '�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.���i�敪                   IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.���i�敪��                 IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�i�ڋ敪                   IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�i�ڋ敪��                 IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�Q�R�[�h                   IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�i��                       IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�i�ږ�                     IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�i�ڗ���                   IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.���b�gNO                   IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�����N����                 IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ŗL�L��                   IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ܖ�����                   IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.���ɓ�                     IS '���ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.���Ɍ��R�[�h               IS '���Ɍ��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.���Ɍ���                   IS '���Ɍ���'
/ 
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�݌ɒP��                   IS '�݌ɒP��'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.������P�[�X�݌ɐ�         IS '������P�[�X�݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.������o���݌ɐ�           IS '������o���݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.������P�[�X�o�Ɏw����     IS '������P�[�X�o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.������o���o�Ɏw����       IS '������o���o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�Ǖi�P�[�X�݌ɐ�           IS '�Ǖi�P�[�X�݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�Ǖi�o���݌ɐ�             IS '�Ǖi�o���݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�Ǖi�P�[�X�o�Ɏw����       IS '�Ǖi�P�[�X�o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�Ǖi�o���o�Ɏw����         IS '�Ǖi�o���o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�����t�Ǖi�P�[�X�݌ɐ�     IS '�����t�Ǖi�P�[�X�݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�����t�Ǖi�o���݌ɐ�       IS '�����t�Ǖi�o���݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�����t�Ǖi�P�[�X�o�Ɏw���� IS '�����t�Ǖi�P�[�X�o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�����t�Ǖi�o���o�Ɏw����   IS '�����t�Ǖi�o���o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�s�Ǖi�P�[�X�݌ɐ�         IS '�s�Ǖi�P�[�X�݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�s�Ǖi�o���݌ɐ�           IS '�s�Ǖi�o���݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�s�Ǖi�P�[�X�o�Ɏw����     IS '�s�Ǖi�P�[�X�o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�s�Ǖi�o���o�Ɏw����       IS '�s�Ǖi�o���o�Ɏw����'
/
-- ***** 2009/09/24 #1634 S *****
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ۗ��P�[�X�݌ɐ�           IS '�ۗ��P�[�X�݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ۗ��o���݌ɐ�             IS '�ۗ��o���݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ۗ��P�[�X�o�Ɏw����       IS '�ۗ��P�[�X�o�Ɏw����'
/
COMMENT ON COLUMN APPS.XXSKY_�h�����N�݌ɏ��_��{_V.�ۗ��o���o�Ɏw����         IS '�ۗ��o���o�Ɏw����'
/
-- ***** 2009/09/24 #1634 E *****

