/*************************************************************************
 * 
 * View  Name      : XXSKZ_�݌ɏ��_��{_V
 * Description     : XXSKZ_�݌ɏ��_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�݌ɏ��_��{_V
(
 ����
,���`�R�[�h
,���`
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
,����݌ɐ�
,�������ɐ�
,�����o�ɐ�
,�������ɗ\�萔
,�����o�ɗ\�萔
,�����݌ɐ�
,�I���P�[�X��
,�I���o����
,�������ɐ�
,�����o�ɐ�
,���݌ɐ�
,���ɗ\�萔
,�o�ɗ\�萔
,�����\��
)
AS
SELECT
         PRD.yyyymm                                         yyyymm              --����
        ,IWM.attribute1                                     cust_stc_whse       --���`�R�[�h
        ,FLV01.meaning                                      cust_stc_whse_name  --���`
        ,STRN.whse_code                                     whse_code           --�q�ɃR�[�h
        ,IWM.whse_name                                      whse_name           --�q�ɖ�
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
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                                            lot_no              --���b�gNo('DEFALTLOT'�A���b�g��������'0')
        ,CASE WHEN ITEM.lot_ctl = 1 THEN ILM.attribute1  --���b�g�Ǘ��i   �������N�������擾
              ELSE                       NULL            --�񃍃b�g�Ǘ��i ��NULL
         END                                                lot_date            --�����N����
        ,CASE WHEN ITEM.lot_ctl = 1 THEN ILM.attribute2  --���b�g�Ǘ��i   �����b�gNO���擾
              ELSE                       NULL            --�񃍃b�g�Ǘ��i ��NULL
         END                                                lot_sign            --�ŗL�L��
        ,CASE WHEN ITEM.lot_ctl = 1 THEN ILM.attribute3  --���b�g�Ǘ��i   �����b�gNO���擾
              ELSE                       NULL            --�񃍃b�g�Ǘ��i ��NULL
         END                                                best_bfr_date       --�ܖ�����
        ,NVL( STRN.m_start_qty     , 0 )                    m_start_qty         --����݌ɐ�
        ,NVL( STRN.this_in_qty     , 0 )                    this_in_qty         --�������ɐ�
        ,NVL( STRN.this_out_qty    , 0 )                    this_out_qty        --�����o�ɐ�
        ,NVL( STRN.this_sch_in_qty , 0 )                    this_sch_in_qty     --�������ɗ\�萔
        ,NVL( STRN.this_sch_out_qty, 0 )                    this_sch_out_qty    --�����o�ɗ\�萔
        ,STRN.m_end_qty                                     m_end_qty           --�����݌ɐ�
        ,NVL( STRN.stc_r_cs_qty    , 0 )                    stc_r_cs_qty        --�I���P�[�X��
        ,NVL( STRN.stc_r_qty       , 0 )                    stc_r_qty           --�I���o����
        ,NVL( STRN.next_in_qty     , 0 )                    next_in_qty         --�������ɐ�
        ,NVL( STRN.next_out_qty    , 0 )                    next_out_qty        --�����o�ɐ�
        ,NVL( STRN.loct_onhand     , 0 )                    loct_onhand         --���݌ɐ�
        ,NVL( STRN.sch_in_qty      , 0 )                    sch_in_qty          --���ɗ\�萔
        ,NVL( STRN.sch_out_qty     , 0 )                    sch_out_qty         --�o�ɗ\�萔
        ,STRN.enable_qty                                    enable_qty          --�����\��
  FROM  (  --�q�ɃR�[�h�A�ۊǏꏊ�R�[�h�A�i��ID�A���b�gID�P�ʂŏW�v
           SELECT  TRAN.whse_code                           whse_code           --�q�ɃR�[�h
                  ,TRAN.location                            location            --�ۊǏꏊ�R�[�h
                  ,TRAN.item_id                             item_id             --�i��ID
                  ,TRAN.lot_id                              lot_id              --���b�gID
                  ,SUM( TRAN.m_start_qty )                  m_start_qty         --����݌ɐ�
                  ,SUM( TRAN.this_in_qty )                  this_in_qty         --�������ɐ�
                  ,SUM( TRAN.this_out_qty )                 this_out_qty        --�����o�ɐ�
                  ,SUM( TRAN.this_sch_in_qty )              this_sch_in_qty     --�������ɗ\�萔
                  ,SUM( TRAN.this_sch_out_qty )             this_sch_out_qty    --�����o�ɗ\�萔
                   --�����݌ɐ�(����݌ɐ��{�������ɐ��|�����o�ɐ�)
                  ,SUM( NVL( TRAN.m_start_qty, 0 )
                      + NVL( TRAN.this_in_qty, 0 ) - NVL( TRAN.this_out_qty, 0 )
                   )                                        m_end_qty           --�����݌ɐ�
                  ,SUM( TRAN.stc_r_cs_qty )                 stc_r_cs_qty        --�I���P�[�X��
                  ,SUM( TRAN.stc_r_qty )                    stc_r_qty           --�I���o����
                  ,SUM( TRAN.next_in_qty )                  next_in_qty         --�������ɐ�
                  ,SUM( TRAN.next_out_qty )                 next_out_qty        --�����o�ɐ�
                  ,SUM( TRAN.loct_onhand )                  loct_onhand         --���݌ɐ�
                  ,SUM( TRAN.sch_in_qty )                   sch_in_qty          --���ɗ\�萔
                  ,SUM( TRAN.sch_out_qty )                  sch_out_qty         --�o�ɗ\�萔
                   --�����\��(���݌ɐ��{���ɗ\�萔�|�o�ɗ\�萔)
                  ,SUM( NVL( TRAN.loct_onhand, 0 )
                      + NVL( TRAN.sch_in_qty , 0 )
                      - NVL( TRAN.sch_out_qty, 0 )
                   )                                        enable_qty          --�����\��
             FROM  (
                     --======================================================================
                     -- �I�����ʃA�h�I������I���݌ɐ����擾
                     --======================================================================
                      SELECT
                              XSIR.invent_whse_code         whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,XSIR.item_id                  item_id             --�i��ID
                             ,NVL( XSIR.lot_id, 0 )         lot_id              --���b�gID�iNULL��DEFAULTLOT�j
                             ,TRUNC( NVL( XSIR.case_amt, 0 ) + ( NVL( XSIR.loose_amt, 0 ) / DECODE( XSIR.content, NULL, 1, 0, 1, XSIR.content ) ) )
                                                            stc_r_cs_qty        --�I���P�[�X�� (�I�����ʃA�h�I���e�[�u���̂݃P�[�X���ƃo�����̘a�ő����ƂȂ��Ă���)
                             ,( NVL( XSIR.case_amt, 0 ) * NVL( XSIR.content, 0 ) ) + NVL( XSIR.loose_amt, 0 )
                                                            stc_r_qty           --�I���o����   (�I�����ʃA�h�I���e�[�u���̂݃P�[�X���ƃo�����̘a�ő����ƂȂ��Ă���)
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxinv_stc_inventory_result    XSIR                --�I�����ʃA�h�I��
                             ,xxskz_item_locations_v        XILV                --�ۊǏꏊ�擾�p
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                            ( XSIR.case_amt <> 0  OR  XSIR.loose_amt <> 0 )
                         AND  TO_CHAR( XSIR.invent_date, 'YYYYMM' ) = TO_CHAR( PRD.this_last_day, 'YYYYMM' )  --�����f�[�^��ΏۂƂ���
                         AND  XSIR.invent_whse_code         = XILV.whse_code
                         AND  XILV.allow_pickup_flag        = '1'               --�o�׈����Ώۃt���O
                     --<< �I�����ʃA�h�I������I���݌ɐ����擾 END >>--
                    UNION ALL
                    --=====================================================================================
                    -- ���b�g�ʌ����݌Ƀe�[�u�����猎��݌ɐ�(���߂̃N���[�Y��v���ԃf�[�^)���擾
                    --=====================================================================================
                      SELECT  IPB.whse_code                 whse_code           --�q�ɃR�[�h
                             ,IPB.location                  location            --�ۊǏꏊ�R�[�h
                             ,IPB.item_id                   item_id             --�i��ID
                             ,IPB.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,IPB.loct_onhand               m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  ic_perd_bal                   IPB                 --���b�g�ʌ����݌�
                             ,ic_cldr_dtl                   ICD1                --�݌ɃJ�����_
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ��擾
                                 SELECT  MAX( ICD2.period_end_date )  period_end_date
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                              --���߂̃N���[�Y�݌ɉ�v���Ԃł̃f�[�^����
                              ICD1.orgn_code                = 'ITOE'
                         AND  ICD1.period_end_date          = PRD.period_end_date
                         AND  IPB.period_id                 = ICD1.period_id
                    --<< ����݌ɐ� END >>--
                    UNION ALL
                    --======================================================================
                    -- �����E�����̓��o�ɐ�(����)���擾    ������ = �N���[�Y��v���Ԃ̎���
                    --   �P�DOPM�����g�����U�N�V����
                    --   �Q�DOPM�ۗ��g�����U�N�V����
                    --
                    -- �y�ȉ��͕W���g�����U�N�V�����ɖ����f�̎��уf�[�^  �����݌ɂɂ����f�z
                    --   �R�D�ړ����Ɏ���(�o�ɕ񍐑҂�)
                    --   �S�D�ړ��o�Ɏ���(���ɕ񍐑҂�)
                    --   �T�D�ړ����Ɏ���(���ђ���)
                    --   �U�D�ړ��o�Ɏ���(���ђ���)
                    --   �V�D�o�ׁE�q�֕ԕi����(EBS���ьv��҂�)
                    --   �W�D�x������(EBS���ьv��҂�)
                    --======================================================================
                      -------------------------------------------------------------
                      -- �P�DOPM�����g�����U�N�V����
                      -------------------------------------------------------------
                      -- �@�w�ړ�(�ϑ�����)�x�w�����݌Ɂx�w�ړ����ђ����x�͓���or�o�ɔ����������ōs�Ȃ�
                      SELECT  ITC.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITC.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITC.item_id                   item_id             --�i��ID
                             ,ITC.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN ITC.trans_qty > 0 THEN                            --����������̒l
                                  ITC.trans_qty
                              END END                       this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN ITC.trans_qty < 0 THEN                            --����������̒l
                                  ABS( ITC.trans_qty )
                              END END                       this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN ITC.trans_qty > 0 THEN                            --����������̒l
                                  ITC.trans_qty
                              END END                       next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN ITC.trans_qty < 0 THEN                            --����������̒l
                                  ABS( ITC.trans_qty )
                              END END                       next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_ic_tran_cmp_arc                   ITC     --OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                              (   ITC.doc_type             <> 'ADJI'            --�݌ɒ����ȊO
                               OR ITC.reason_code           = 'X977'            --�����݌�
                               OR ITC.reason_code           = 'X123'            --�ړ����ђ���
                              )
                         AND  ITC.trans_qty                <> 0
                         AND  TRUNC( ITC.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --������ȍ~�̃f�[�^
                    UNION ALL
                      -- �A�w�����݌Ɂx�w�ړ����ђ����x�ȊO�̍݌ɒ����f�[�^�͓���or�o�ɔ�����󕥋敪�}�X�^�ōs�Ȃ�
                      --   �ˁy���R�z�w�d����ԕi�x�̓}�C�i�X�l�̓��Ɉ������A�}�C�i�X�l�̃P�[�X�����݂���
                      SELECT  ITC.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITC.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITC.item_id                   item_id             --�i��ID
                             ,ITC.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN XRPM.rcv_pay_div = '1' THEN           --���
                                  ITC.trans_qty
                              END END                       this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN XRPM.rcv_pay_div = '-1' THEN          --���o
                                  ITC.trans_qty * -1
                              END END                       this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN XRPM.rcv_pay_div = '1' THEN           --���
                                  ITC.trans_qty
                              END END                       next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN XRPM.rcv_pay_div = '-1' THEN          --���o
                                  ITC.trans_qty * -1
                              END END                       next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_rcv_pay_mst             XRPM                --�󕥋敪�A�h�I���}�X�^
                             ,ic_adjs_jnl                   IAJ                 --OPM�݌ɒ����W���[�i��
                             ,ic_jrnl_mst                   IJM                 --OPM�W���[�i���}�X�^
                             ,xxcmn_ic_tran_cmp_arc                   ITC                 --OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         -- �󕥋敪�A�h�I���}�X�^�̏���
                              XRPM.doc_type                 = 'ADJI'            --�݌ɒ���
                         AND  XRPM.reason_code              <> 'X977'           --�����݌� �ȊO
                         AND  XRPM.reason_code              <> 'X123'           --�ړ����ђ��� �ȊO
                         AND  XRPM.use_div_invent           = 'Y'
                         -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITC.trans_qty                 <> 0
                         AND  ITC.doc_type                  = XRPM.doc_type
                         AND  ITC.reason_code               = XRPM.reason_code
                         AND  TRUNC( ITC.trans_date )       >= TRUNC( PRD.this_last_day, 'MONTH' )  --������ȍ~�̃f�[�^
                         -- OPM�݌ɒ����W���[�i���Ƃ̌���
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPM�W���[�i���}�X�^�Ƃ̌���
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ �P�DOPM�����g�����U�N�V����  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �Q�DOPM�ۗ��g�����U�N�V����
                      -------------------------------------------------------------
                      -- �@�w�ړ��֘A�x�w���Y�֘A�x�͓���or�o�ɔ����������ōs�Ȃ�
                      SELECT  ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN ITP.trans_qty > 0 THEN                            --����������̒l
                                  ITP.trans_qty
                              END END                       this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN ITP.trans_qty < 0 THEN                            --����������̒l
                                  ABS( ITP.trans_qty )
                              END END                       this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN ITP.trans_qty > 0 THEN                            --����������̒l
                                  ITP.trans_qty
                              END END                       next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN ITP.trans_qty < 0 THEN                            --����������̒l
                                  ABS( ITP.trans_qty )
                              END END                       next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_ic_tran_pnd_arc                   ITP       --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  (   ITP.doc_type              = 'XFER'            --�ړ��֘A
                               OR ITP.doc_type              = 'PROD'            --���Y�֘A
                              )
                         AND  ITP.completed_ind             = '1'               --����(���тƂ��Ď莝���݌ɂɔ��f��)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --������ȍ~�̃f�[�^
                    UNION ALL
                      -- �A�w�󒍊֘A�x�͓���or�o�ɔ�����󒍃^�C�v�敪�ōs�Ȃ�
                      --   �ˁy���R�z�w�q�֕ԕi����x�̓}�C�i�X�l�̓��Ɉ���
                      SELECT  ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --�w�q�֕ԕi����x�̏ꍇ
                                  ITP.trans_qty                                             --�}�C�i�X�l�̓���
                              END END                       this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --�w�o�ץ�x���x�̏ꍇ
                                  ITP.trans_qty * -1
                              END END                       this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --�w�q�֕ԕi����x�̏ꍇ
                                  ITP.trans_qty                                             --�}�C�i�X�l�̓���
                              END END                       next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --�w�o�ץ�x���x�̏ꍇ
                                  ITP.trans_qty * -1
                              END END                       next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_ic_tran_pnd_arc                   ITP       --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,wsh_delivery_details          WDD                 --�o�ה�������
                             ,xxcmn_oe_order_headers_all_arc          OHA       --�󒍃w�b�_�i�W���j�o�b�N�A�b�v
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  ITP.doc_type                  = 'OMSO'            --�󒍊֘A
                         AND  ITP.completed_ind             = '1'               --����(���тƂ��Ď莝���݌ɂɔ��f��)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --������ȍ~�̃f�[�^
                         --�o�ה������׃f�[�^�̎擾
                         AND  ITP.line_detail_id            = WDD.delivery_detail_id
                         --�󒍃w�b�_�f�[�^�̎擾
                         AND  WDD.source_header_id          = OHA.header_id
                         AND  WDD.org_id                    = OHA.org_id
                         --�󒍃^�C�v�f�[�^�̎擾
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                    UNION ALL
                      -- �B�w�w���֘A�i�d�����сj�x�͑S�ē��Ɉ����ōs�Ȃ�
                      SELECT  ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                ITP.trans_qty
                              END                           this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                ITP.trans_qty
                              END                           next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  ic_tran_pnd                   ITP                 --OPM�ۗ��g�����U�N�V����
                             ,rcv_shipment_lines                      RSL                 --�������
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  ITP.doc_type                  = 'PORC'            --�w���֘A
                         AND  ITP.completed_ind             = '1'               --����(���тƂ��Ď莝���݌ɂɔ��f��)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --������ȍ~�̃f�[�^
                         --������׃f�[�^�̎擾
                         AND  RSL.source_document_code = 'PO'                   --�d��
                         AND  RSL.shipment_header_id = ITP.doc_id
                         AND  RSL.line_num = ITP.doc_line
                    UNION ALL
                      -- �C�w�w���֘A�i�󒍁j�x�͓���or�o�ɔ�����󒍃^�C�v�敪�ōs�Ȃ�
                      --   �ˁy���R�z�w�d����ԕi�x�̓}�C�i�X�l�̏o�Ɉ���
                      SELECT  ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --�w�q�֕ԕi�x�̏ꍇ
                                  ITP.trans_qty
                              END END                       this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --�w�x����ԕi�x�̏ꍇ
                                  ITP.trans_qty * -1                                        --�}�C�i�X�l�̏o��
                              END END                       this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --�w�q�֕ԕi�x�̏ꍇ
                                  ITP.trans_qty
                              END END                       next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --�w�x����ԕi�x�̏ꍇ
                                  ITP.trans_qty * -1                                        --�}�C�i�X�l�̏o��
                              END END                       next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_ic_tran_pnd_arc                   ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,xxcmn_rcv_shipment_lines_arc            RSL                 --������ׁi�W���j�o�b�N�A�b�v
                             ,xxcmn_oe_order_headers_all_arc          OHA                 --�󒍃w�b�_�i�W���j�o�b�N�A�b�v
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  ITP.doc_type                  = 'PORC'            --�w���֘A
                         AND  ITP.completed_ind             = '1'               --����(���тƂ��Ď莝���݌ɂɔ��f��)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --������ȍ~�̃f�[�^
                         --������׃f�[�^�̎擾
                         AND  RSL.source_document_code = 'RMA'                  --��
                         AND  RSL.shipment_header_id = ITP.doc_id
                         AND  RSL.line_num = ITP.doc_line
                         --�󒍃w�b�_�f�[�^�̎擾
                         AND  RSL.oe_order_header_id        = OHA.header_id
                         --�󒍃^�C�v�f�[�^�̎擾
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                      --[ �Q�DOPM�ۗ��g�����U�N�V����  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �R�D�ړ����Ɏ���(�o�ɕ񍐑҂�)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                MLD.actual_quantity
                              END                           this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                MLD.actual_quantity
                              END                           next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                              --���݌ɐ�
                             ,MLD.actual_quantity           loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH               --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v�� �� EBS�݌ɖ����f
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
                      --[ �R�D�ړ����Ɏ���(���o�ɕ񍐑҂�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �S�D�ړ��o�Ɏ���(���ɕ񍐑҂�)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                MLD.actual_quantity
                              END                           this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                MLD.actual_quantity
                              END                           next_out_qty        --�����o�ɐ�
                              --���݌ɐ�
                             ,MLD.actual_quantity * -1      loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v�� �� EBS�݌ɖ����f
                         AND  MRIH.status                   IN ( '04', '06' )   --04:�o�ɕ񍐗L�A06:���o�ɕ񍐗L
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '20'              --�o�Ɏ���
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --�o�Ɍ��ۊǏꏊ���擾
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ �S�D�ړ��o�Ɏ���(���o�ɕ񍐑҂�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �T�D�ړ����Ɏ���(���ђ���)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                              --���݌ɐ�
                             ,NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                                                            loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  MRIH.comp_actual_flg          = 'Y'               --���ьv�� �� EBS�݌ɔ��f��
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
                      --[ �T�D�ړ����Ɏ���(���ђ���)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �U�D�ړ��o�Ɏ���(���ђ���)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           next_out_qty        --�����o�ɐ�
                              --���݌ɐ�
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) ) * -1
                                                            loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  MRIH.comp_actual_flg          = 'Y'               --���ьv�� �� EBS�݌ɖ����f��
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
                      --[ �U�D�ړ��o�Ɏ���(���ђ���)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �V�D�o�ׁE�q�֕ԕi����(EBS���ьv��҂�)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                              --�������ɐ�
                             ,CASE WHEN TRUNC( OHA.shipped_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN OTTA.attribute1 = '3' THEN                          --�w�q�֕ԕi�x�̏ꍇ
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 )
                              END END                       this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( OHA.shipped_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                CASE WHEN OTTA.attribute1 = '1' THEN                          --�w�o�ׁx�̏ꍇ
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END END                       this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                              --�������ɐ�
                             ,CASE WHEN TRUNC( OHA.shipped_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN OTTA.attribute1 = '3' THEN                          --�w�q�֕ԕi�x�̏ꍇ
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 )
                              END END                       next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( OHA.shipped_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                CASE WHEN OTTA.attribute1 = '1' THEN                          --�w�o�ׁx�̏ꍇ
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END END                       next_out_qty        --�����o�ɐ�
                              --���݌ɐ�
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_order_headers_all_arc       OHA                 --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_order_lines_all_arc         OLA                 --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  OHA.req_status                = '04'              --���ьv���
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
                      --[ �V�D�o�ׁE�q�֕ԕi����(���ו񍐑҂�)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �W�D�x������(EBS���ьv��҂�)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( OHA.shipped_date ) <= PRD.this_last_day THEN   --�������ȓ�
                                   ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                      * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                              --�����o�ɐ�
                             ,CASE WHEN TRUNC( OHA.shipped_date ) >  PRD.this_last_day THEN   --�����ȏ�(����������)
                                   ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                      * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           next_out_qty        --�����o�ɐ�
                              --���݌ɐ�
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  xxcmn_order_headers_all_arc       OHA                 --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_order_lines_all_arc         OLA                 --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE  OHA.req_status                = '08'              --���ьv���
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
                      --[ �W�D�x������(���ו񍐑҂�)  End ]--
                    --<< �����E�����̓��o�ɐ�(����)���擾  END >>--
                    UNION ALL
                    --======================================================================
                    -- �莝���݌ɂ��猻�݌ɐ����擾
                    --======================================================================
                      SELECT  ILI.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ILI.location                  location            --�ۊǏꏊ�R�[�h
                             ,ILI.item_id                   item_id             --�i��ID
                             ,ILI.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,ILI.loct_onhand               loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM  ic_loct_inv                   ILI                 --OPM�莝������
                    --<< �莝���݌ɂ��猻�݌ɐ����擾  END >>--
--
                    UNION ALL
                    --======================================================================
                    -- ������ȍ~�̓��ɗ\�萔���e�g�����U�N�V��������擾
                    --  �P�D��������\��
                    --  �Q�D�ړ����ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                    --  �R�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)
                    --  �S�D���Y���ɗ\��(�����i[�����i]�A���Y��)
                    --  �T�D���Y���ɗ\�� �i�ڐU�� �i��U��
                    --======================================================================
                    --======================================================================
                      -------------------------------------------------------------
                      -- �P�D��������\��
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,IIMB.item_id                  item_id             --�i��ID
                             ,NVL( ILM.lot_id, 0 )          lot_id              --���b�gID (NULL�ł͏W�v����Ȃ���NVL�g�p)
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,CASE WHEN TO_DATE( PHA.attribute4, 'YYYY/MM/DD' ) <= PRD.this_last_day THEN   --�������ȓ�
                                PLA.quantity
                              END                           this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,PLA.quantity                  sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM
                              po_headers_all                PHA                 --�����w�b�_
                             ,po_lines_all                  PLA                 --��������
                             ,xxskz_item_locations_v        XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,ic_item_mst_b                 IIMB                --OPM�i�ڃ}�X�^(OPM�i��ID�擾�p)
                             ,mtl_system_items_b            MSIB                --INV�i�ڃ}�X�^(OPM�i��ID�擾�p)
                             ,ic_lots_mst                   ILM                 --OPM���b�g�}�X�^(���b�gID�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         --�����w�b�_�̏���
                              PHA.attribute1                IN ( '20', '25' )   --20:�����쐬�ρA25:�������
                         --�������ׂƂ̌���
                         AND  NVL( PLA.attribute13, 'N' )  <> 'Y'               --������
                         AND  NVL( PLA.cancel_flag, 'N' )  <> 'Y'               --�������׈ȊO
                         AND  PHA.po_header_id              = PLA.po_header_id
                         --�q�ɃR�[�h�擾
                         AND  PHA.attribute5                = XILV.segment1
                         --OPM�i��ID�擾
                         AND  PLA.item_id                   = MSIB.inventory_item_id
                         AND  MSIB.organization_id          = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
                         AND  MSIB.segment1                 = IIMB.item_no
                         --OPM���b�gID�擾
                         AND  IIMB.item_id                  = ILM.item_id
                         AND (   ( IIMB.lot_ctl = 1 AND PLA.attribute1 = ILM.lot_no )  --���b�g�Ǘ��i
                              OR ( IIMB.lot_ctl = 0 AND ILM.lot_id     = 0          )  --�񃍃b�g�Ǘ��i
                             )
                         --���ɐ�ۊǏꏊ���擾
                         AND  PHA.attribute5 = XILV.segment1
                      --[ �P�D��������\��  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �Q�D�ړ����ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,CASE WHEN MRIH.schedule_arrival_date <= PRD.this_last_day THEN   --�������ȓ�
                                MLD.actual_quantity
                              END                           this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,MLD.actual_quantity           sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         --�ړ��˗�/�w���w�b�_�̏���
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --���і��v��
                         AND  MRIH.status                   IN ( '02', '03' )   --02:�˗��ρA03:������
                         --�ړ��˗�/�w�����ׂƂ̌���
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'           --�����ł͂Ȃ�
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '20'              --�ړ�
                         AND  MLD.record_type_code          = '10'              --�w��
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --���ɐ�ۊǏꏊ���擾
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ �Q�D�ړ����ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �R�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,CASE WHEN MRIH.schedule_arrival_date <= PRD.this_last_day THEN   --�������ȓ�
                                MLD.actual_quantity
                              END                           this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,MLD.actual_quantity           sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
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
                      --[ �R�D�ړ����ɗ\��(�o�ɕ񍐗L �ϑ�����)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �S�D���Y���ɗ\��(�����i[�����i]�A���Y��)
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --�������ȓ�
                                GMD.plan_qty
                              END                           this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,GMD.plan_qty                  sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                             ,gmd_routings_b                GRB                 --�H���}�X�^
                             ,xxcmn_gme_material_details_arc          GMD                 --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         --���Y�o�b�`�̏���
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:�ۗ��A2:WIP
                         --�H���}�X�^�Ƃ̌���
                         AND  GRB.routing_class             NOT IN ( '61', '62', '70' )  -- �i�ڐU��(70)�A���(61,62) �ȊO
                         AND  GBH.routing_id                = GRB.routing_id
                         --���Y�����ڍׂƂ̌���(�����i�A���Y���̂�)
                         AND  GMD.line_type                 IN ( '1', '2' )     --1:�����i�A2:���Y��
                         AND  GBH.batch_id                  = GMD.batch_id
                         --�ۗ��݌Ƀg�����U�N�V����
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- �������Ă��Ȃ�(�˗\��)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                         AND  ITP.location                  = GRB.attribute9
                      --[ �S�D���Y���ɗ\��(�����i[�����i]�A���Y��)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      --  �T�D���Y���ɗ\�� �i�ڐU�� �i��U��
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --�������ȓ�
                                GMD.plan_qty
                              END                           this_sch_in_qty     --�������ɗ\�萔
                             ,0                             this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,GMD.plan_qty                  sch_in_qty          --���ɗ\�萔
                             ,0                             sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                             ,gmd_routings_b                GRB                 --�H���}�X�^
                             ,xxcmn_gme_material_details_arc          GMD                 --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         --���Y�o�b�`�̏���
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:�ۗ��A2:WIP
                         --�H���}�X�^�Ƃ̌���
                         AND  GRB.routing_class             = '70'              -- �i�ڐU��
                         AND  GBH.routing_id                = GRB.routing_id
                         --���Y�����ڍׂƂ̌���(�����i�A���Y���̂�)
                         AND  GMD.line_type                 = 1                 -- �U�֐�
                         AND  GBH.batch_id                  = GMD.batch_id
                         --�ۗ��݌Ƀg�����U�N�V����
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- �������Ă��Ȃ�(�˗\��)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.lot_id                   <> 0                 --�w���ށx�͗L�蓾�Ȃ�
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                      --[ �T�D���Y���ɗ\�� �i�ڐU�� �i��U��  END ]--
                     -- << ���ɗ\�萔���e�g�����U�N�V��������擾  END >>
                    UNION ALL
                     --======================================================================
                     -- �o�ɗ\�萔���e�g�����U�N�V��������擾
                     --  �P�D�ړ��o�ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                     --  �Q�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)
                     --  �R�D�󒍏o�ח\��
                     --  �S�D�L���o�ח\��
                     --  �T�D���Y���������\��
                     --  �U�D���Y�o�ɗ\�� �i�ڐU�� �i��U��
                     --  �V�D�����݌ɏo�ɗ\��
                     --======================================================================
                      -------------------------------------------------------------
                      -- �P�D�ړ��o�ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,CASE WHEN MRIH.schedule_ship_date <= PRD.this_last_day THEN   --�������ȓ�
                                MLD.actual_quantity
                              END                           this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,MLD.actual_quantity           sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
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
                      --[ �P�D�ړ��o�ɗ\��(�w�� �ϑ����聕�ϑ��Ȃ�)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �Q�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,CASE WHEN MRIH.schedule_ship_date <= PRD.this_last_day THEN   --�������ȓ�
                                MLD.actual_quantity
                              END                           this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,MLD.actual_quantity           sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
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
                      --[ �Q�D�ړ��o�ɗ\��(���ɕ񍐗L �ϑ�����)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �R�D�󒍏o�ח\��
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                              --�����o�ɗ\�萔
                             ,CASE WHEN OHA.schedule_ship_date <= PRD.this_last_day THEN   --�������ȓ�
                                   MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                              --�o�ɗ\�萔
                             ,MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                            sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_order_lines_all_arc         OLA                 --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
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
                      --[ �R�D�󒍏o�ח\��  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �S�D�L���o�ח\��
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                              --�����o�ɗ\�萔
                             ,CASE WHEN OHA.schedule_ship_date <= PRD.this_last_day THEN   --�������ȓ�
                                   MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                              --�o�ɗ\�萔
                             ,MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                            sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_order_lines_all_arc         OLA                 --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                             ,xxcmn_mov_lot_details_arc         MLD                 --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                             ,oe_transaction_types_all      OTTA                --�󒍃^�C�v
                             ,xxskz_item_locations2_v       XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
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
                      --[ �S�D�L���o�ח\��  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �T�D���Y���������\��
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --�������ȓ�
                                ITP.trans_qty * -1
                              END                           this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,ITP.trans_qty * -1            sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                             ,gmd_routings_b                GRB                 --�H���}�X�^
                             ,xxcmn_gme_material_details_arc          GMD                 --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         --���Y�o�b�`�̏���
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:�ۗ��A2:WIP
                         --�H���}�X�^�Ƃ̌���
                         AND  GBH.routing_id                = GRB.routing_id
                         AND  GRB.routing_class             NOT IN ( '61', '62', '70' )  -- �i�ڐU��(70)�A���(61,62) �ȊO
                         --���Y�����ڍׂƂ̌���(�����̂�)
                         AND  GMD.line_type                 = -1                -- -1:����
                         AND  GBH.batch_id                  = GMD.batch_id
                         --�ۗ��݌Ƀg�����U�N�V����
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- �������Ă��Ȃ�(�˗\��)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                         AND  ITP.location                  = GRB.attribute9
                      --[ �T�D���Y���������\��  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      --  �U�D���Y�o�ɗ\�� �i�ڐU�� �i��U��
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --�q�ɃR�[�h
                             ,ITP.location                  location            --�ۊǏꏊ�R�[�h
                             ,ITP.item_id                   item_id             --�i��ID
                             ,ITP.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --�������ȓ�
                                GMD.plan_qty
                              END                           this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,GMD.plan_qty                  sch_out_qty         --�o�ɗ\�萔
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                             ,gmd_routings_b                GRB                 --�H���}�X�^
                             ,xxcmn_gme_material_details_arc          GMD                 --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         --���Y�o�b�`�̏���
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:�ۗ��A2:WIP
                         --�H���}�X�^�Ƃ̌���
                         AND  GRB.routing_class             = '70'              -- �i�ڐU��
                         AND  GBH.routing_id                = GRB.routing_id
                         --���Y�����ڍׂƂ̌���(�����i�A���Y���̂�)
                         AND  GMD.line_type                 = -1                -- �U�֌�
                         AND  GBH.batch_id                  = GMD.batch_id
                         --�ۗ��݌Ƀg�����U�N�V����
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- �������Ă��Ȃ�(�˗\��)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.lot_id                   <> 0                 --�w���ށx�͗L�蓾�Ȃ�
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                      --[ �U�D���Y�o�ɗ\�� �i�ڐU�� �i��U��  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- �V�D�����݌ɏo�ɗ\��
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --�q�ɃR�[�h
                             ,XILV.segment1                 location            --�ۊǏꏊ�R�[�h
                             ,MLD.item_id                   item_id             --�i��ID
                             ,MLD.lot_id                    lot_id              --���b�gID
                             ,0                             stc_r_cs_qty        --�I���P�[�X��
                             ,0                             stc_r_qty           --�I���o����
                             ,0                             m_start_qty         --����݌ɐ�
                             ,0                             this_in_qty         --�������ɐ�
                             ,0                             this_out_qty        --�����o�ɐ�
                             ,0                             this_sch_in_qty     --�������ɗ\�萔
                             ,CASE WHEN TO_DATE( PHA.attribute4, 'YYYY/MM/DD' ) <= PRD.this_last_day THEN   --�������ȓ�
                                PLA.quantity
                              END                           this_sch_out_qty    --�����o�ɗ\�萔
                             ,0                             next_in_qty         --�������ɐ�
                             ,0                             next_out_qty        --�����o�ɐ�
                             ,0                             loct_onhand         --���݌ɐ�
                             ,0                             sch_in_qty          --���ɗ\�萔
                             ,PLA.quantity                  sch_out_qty         --�o�ɗ\�萔
                        FROM
                              po_headers_all                PHA                 --�����w�b�_
                             ,po_lines_all                  PLA                 --��������
                             ,xxinv_mov_lot_details         MLD                 --�ړ����b�g�ڍ�
                             ,xxskz_item_locations_v        XILV                --�ۊǏꏊ�}�X�^(�q�ɃR�[�h�擾�p)
                             ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:�N���[�Y'
                              )  PRD
                       WHERE
                         --�����w�b�_�̏���
                              PHA.attribute1                IN ( '20', '25' )   --20:�����쐬�ρA25:�������
                         AND  PHA.attribute11               = '3'
                         --�������ׂƂ̌���
                         AND  NVL( PLA.attribute13, 'N' )  <> 'Y'               --������
                         AND  NVL( PLA.cancel_flag, 'N' )  <> 'Y'
                         AND  PHA.po_header_id              = PLA.po_header_id
                         --�ړ����b�g�ڍׂƂ̌���
                         AND  MLD.document_type_code        = '50'              --����
                         AND  MLD.record_type_code          = '10'              --�w��
                         AND  PLA.po_line_id                = MLD.mov_line_id
                         --�q�ɃR�[�h�擾
                         AND  PLA.attribute12               = XILV.segment1
                      --[ �V�D�����݌ɏo�ɗ\��  END ]--
                     -- << �o�ɗ\�萔���e�g�����U�N�V��������擾  END >>
                   )  TRAN
           GROUP BY TRAN.whse_code    --�q�ɃR�[�h
                   ,TRAN.location     --�ۊǏꏊ�R�[�h
                   ,TRAN.item_id      --�i��ID
                   ,TRAN.lot_id       --���b�gID
        )  STRN
       ,(  --���߂̃N���[�Y�݌ɉ�v���Ԃ̎���(����)�̖������擾
           SELECT  TO_CHAR( ADD_MONTHS( MAX( ICD2.period_end_date ), 1 ), 'YYYYMM' )  yyyymm
             FROM  ic_cldr_dtl  ICD2
            WHERE  ICD2.orgn_code = 'ITOE'
              AND  ICD2.closed_period_ind <> 1        --'3:�N���[�Y'
        )  PRD
       ,ic_whse_mst                IWM     --�q�Ƀ}�X�^
       ,xxskz_item_locations_v     ILOC    --�ۊǏꏊ�擾�p
       ,xxskz_item_mst_v           ITEM    --�i�ږ��̎擾�p(SYSDATE�Ŏ擾)
       ,xxskz_prod_class_v         PRODC   --���i�敪�擾�p
       ,xxskz_item_class_v         ITEMC   --�i�ڋ敪�擾�p
       ,xxskz_crowd_code_v         CROWD   --�Q�R�[�h�擾�p
       ,ic_lots_mst                ILM     --���b�g�}�X�^
       ,fnd_lookup_values          FLV01   --�N�C�b�N�R�[�h(���`)
 WHERE
   --�q�ɖ��擾�p
        STRN.whse_code             = IWM.whse_code(+)
   --�ۊǏꏊ�擾
   AND  STRN.location              = ILOC.segment1(+)
   --�i�ږ��̎擾(SYSDATE�Ŏ擾)
   AND  STRN.item_id               = ITEM.item_id(+)
   --�i�ڃJ�e�S�����擾
   AND  STRN.item_id               = PRODC.item_id(+)
   AND  STRN.item_id               = ITEMC.item_id(+)
   AND  STRN.item_id               = CROWD.item_id(+)
   --���b�g���擾
   AND  STRN.item_id               = ILM.item_id(+)
   AND  STRN.lot_id                = ILM.lot_id(+)
   --���`�擾
   AND  FLV01.language(+)          = 'JA'                --����
   AND  FLV01.lookup_type(+)       = 'XXCMN_INV_CTRL'    --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+)       = IWM.attribute1      --�N�C�b�N�R�[�h
/
COMMENT ON TABLE APPS.XXSKZ_�݌ɏ��_��{_V IS 'SKYLINK�p �݌ɏ��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.����           IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.���`�R�[�h     IS '���`�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.���`           IS '���`'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�q�ɃR�[�h     IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�q�ɖ�         IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�ۊǏꏊ�R�[�h IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�ۊǏꏊ��     IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�ۊǏꏊ����   IS '�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.���i�敪       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.���i�敪��     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�i�ڋ敪       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�i�ڋ敪��     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�Q�R�[�h       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�i��           IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�i�ږ�         IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�i�ڗ���       IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.���b�gNO       IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�����N����     IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�ŗL�L��       IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�ܖ�����       IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.����݌ɐ�     IS '����݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�������ɐ�     IS '�������ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�����o�ɐ�     IS '�����o�ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�������ɗ\�萔 IS '�������ɗ\�萔'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�����o�ɗ\�萔 IS '�����o�ɗ\�萔'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�����݌ɐ�     IS '�����݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�I���P�[�X��   IS '�I���P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�I���o����     IS '�I���o����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�������ɐ�     IS '�������ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�����o�ɐ�     IS '�����o�ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.���݌ɐ�       IS '���݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.���ɗ\�萔     IS '���ɗ\�萔'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�o�ɗ\�萔     IS '�o�ɗ\�萔'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɏ��_��{_V.�����\��     IS '�����\��'
/
