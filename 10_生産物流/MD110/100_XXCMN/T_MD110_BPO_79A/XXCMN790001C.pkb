CREATE OR REPLACE PACKAGE BODY xxcmn790001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790001c(body)
 * Description      : ��������v�Z����
 * MD.050           : ���b�g�ʎ��ی����v�Z T_MD050_BPO_790
 * MD.070           : ��������v�Z���� T_MD070_BPO_79A
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_table_data         ����ʃ��b�g�ʌ����e�[�u���폜����(A-1)
 *  get_opening_period     �݌ɃI�[�v�����Ԏ擾����(A-2)
 *  get_ins_data           �o�^�f�[�^�擾����
 *  ins_table_batch        �݌Ƀf�[�^���o�E�o�^����(A-3)
 *  get_data_dump          �f�[�^�_���v�擾����
 *  put_success_dump       �����f�[�^�_���v�o�͏���
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/1/31     1.0   Y.Kanami         �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                 EXCEPTION;     -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790001c';  -- �p�b�P�[�W��
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';         -- ���W���[�����ȗ��FXXCMN�}�X�^����
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';  
                                            -- ���b�Z�[�W�F���b�N�擾�G���[
  gv_msg_xxcmn10039 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10039';
                                            -- ���b�Z�[�W�F�I�[�v�����Ԏ擾�G���[
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- ���b�Z�[�W�F�f�[�^�擾�G���[
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';  
                                            -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �o�^�pPL/SQL�\�^
  TYPE doc_type_ttype   IS TABLE OF xxcmn_txn_lot_cost.doc_type%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �����^�C�v
  TYPE doc_id_ttype     IS TABLE OF xxcmn_txn_lot_cost.doc_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ����ID
  TYPE item_id_ttype    IS TABLE OF xxcmn_txn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �i��ID
  TYPE item_code_ttype  IS TABLE OF xxcmn_txn_lot_cost.item_code%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �i�ڃR�[�h
  TYPE lot_id_ttype     IS TABLE OF xxcmn_txn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ���b�gID
  TYPE lot_num_ttype    IS TABLE OF xxcmn_txn_lot_cost.lot_num%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ���b�gNo
  TYPE trans_qty_ttype  IS TABLE OF xxcmn_txn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �������
  TYPE unit_price_ttype IS TABLE OF xxcmn_txn_lot_cost.unit_price%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �P��
--
  -- �o�^�pPL/SQL�\
  gt_doc_type_ins_tab   doc_type_ttype;     -- �����^�C�v
  gt_doc_id_ins_tab     doc_id_ttype;       -- ����ID
  gt_item_id_ins_tab    item_id_ttype;      -- �i��ID
  gt_item_code_ins_tab  item_code_ttype;    -- �i�ڃR�[�h
  gt_lot_id_ins_tab     lot_id_ttype;       -- ���b�gID
  gt_lot_num_ins_tab    lot_num_ttype;      -- ���b�gNo
  gt_trans_qty_ins_tab  trans_qty_ttype;    -- �������
  gt_unit_price_ins_tab unit_price_ttype;   -- �P��
--
  -- ���̓f�[�^�_���v�pPL/SQL�\�^
  TYPE msg_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �݌ɃI�[�v������
  gd_opening_date     DATE;
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : ����ʃ��b�g�ʌ����e�[�u���폜����(A-1)
   ***********************************************************************************/
  PROCEDURE del_table_data(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_table_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �\���b�N�擾
    CURSOR get_tab_lock_cur
    IS
      SELECT  xtlc.lot_id
      FROM    xxcmn_txn_lot_cost xtlc   -- ����ʃ��b�g�ʌ����i�A�h�I���j
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �\���b�N�擾
    -- ===============================
    BEGIN
      <<get_lock_loop>>
      FOR loop_cnt IN get_tab_lock_cur LOOP
        EXIT;
      END LOOP get_lock_loop;
--
    EXCEPTION
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        IF (get_tab_lock_cur%ISOPEN) THEN
          CLOSE get_tab_lock_cur;
        END IF;
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn          -- ���W���[�������́FXXCMN �}�X�^�E�o������
                     ,gv_msg_xxcmn10146 -- ���b�Z�[�W�F���b�N�擾�G���[
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- ����ʃ��b�g�ʌ����i�A�h�I���j�S���폜
    -- =====================================
    DELETE FROM xxcmn_txn_lot_cost xtlc -- ����ʃ��b�g�ʌ����i�A�h�I���j
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( get_tab_lock_cur%ISOPEN ) THEN
        CLOSE get_tab_lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( get_tab_lock_cur%ISOPEN ) THEN
        CLOSE get_tab_lock_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_tab_lock_cur%ISOPEN ) THEN
        CLOSE get_tab_lock_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_table_data;
--
  /**********************************************************************************
   * Procedure Name   : get_opening_period
   * Description      : �݌ɃI�[�v�����Ԏ擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_opening_period(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_opening_period'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_whse_code  CONSTANT VARCHAR2(100)  := 'XXCMN_COST_PRICE_WHSE_CODE';  -- �q�ɃR�[�h
--
    -- *** ���[�J���ϐ� ***
    lt_whse_code  xxcmn_item_locations_v.whse_code%TYPE;                    -- �q�ɃR�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================
    -- �q�ɃR�[�h���擾
    -- =====================================
    lt_whse_code  :=  FND_PROFILE.VALUE(cv_whse_code);
    IF (lt_whse_code IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- ��v���ԊJ�n�����擾
    -- =====================================
    SELECT  MIN(oap.period_start_date)                        -- ��v���ԊJ�n��
    INTO    gd_opening_date
    FROM    org_acct_periods       oap,                       -- �݌ɉ�v����
            xxcmn_item_locations_v ilv                        -- OPM�ۊǏꏊ���VIEW
    WHERE   ilv.whse_code        = lt_whse_code               -- �q�ɃR�[�h
    AND     oap.organization_id  = ilv.mtl_organization_id    -- �g�DID
    AND     oap.open_flag        = 'Y'                        -- �I�[�v���t���O
    ;
    IF (gd_opening_date IS NULL) THEN
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- ���W���[�������́FXXCMN �}�X�^�E�o������
                   ,gv_msg_xxcmn10039   -- ���b�Z�[�W�FAPP-XXCMN-10039 �I�[�v�����Ԏ擾�G���[
                   ),1,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_opening_period;
--
  /**********************************************************************************
   * Procedure Name   : get_ins_data
   * Description      : �o�^�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ins_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type_porc      CONSTANT VARCHAR2(100)  := 'PORC';      -- �w��
    cv_doc_type_adji      CONSTANT VARCHAR2(100)  := 'ADJI';      -- �I������
    cv_dest_type_deliver  CONSTANT VARCHAR2(100)  := 'DELIVER';   -- ����^�C�v�F�w��
    cn_completion         CONSTANT NUMBER         := 1;           -- �����敪�F����
    cv_zero               CONSTANT VARCHAR2(1)    := '0';         -- ���ی����F0
    cv_reason_cd_hamaoka  CONSTANT VARCHAR2(100)  := '�l�����';  -- ���R�R�[�h�F�l�����
--
    -- *** ���[�J���ϐ� ***
    ln_data_cnt           NUMBER DEFAULT 0;   -- �f�[�^�J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �w���f�[�^�A�l������f�[�^�擾�J�[�\��
    CURSOR ins_data_cur IS
      SELECT  itp.doc_type          doc_type                    -- �����^�C�v
            , itp.doc_id            doc_id                      -- ����ID
            , ximv.item_id          item_id                     -- �i��ID
            , ximv.item_no          item_no                     -- �i�ڃR�[�h
            , ilm.lot_id            lot_id                      -- ���b�gID
            , ilm.lot_no            lot_no                      -- ���b�gNo
            , SUM(itp.trans_qty)    trans_qty                   -- ����
            , pla.unit_price        price                       -- �����P��
      FROM    ic_tran_pnd           itp                         -- �ۗ��݌Ƀg�����U�N�V����
            , xxcmn_item_mst_v      ximv                        -- OPM�i�ڏ��View
            , rcv_shipment_lines    rsl                         -- �������
            , rcv_transactions      rt                          -- ������
            , ic_lots_mst           ilm                         -- OPM���b�g�}�X�^
            , po_lines_all          pla                         -- ��������
      WHERE itp.doc_type            =   cv_doc_type_porc        -- �����^�C�v�F�w��
      AND   itp.completed_ind       =   cn_completion           -- �����敪�F����
      AND   itp.trans_date          >=  gd_opening_date         -- �����
      AND   itp.item_id             =   ximv.item_id            -- �i��ID
      AND   ximv.cost_manage_code   =   cv_zero                 -- �����Ǘ��敪�F0
      AND   itp.doc_id              =   rsl.shipment_header_id  -- ����ID
      AND   itp.doc_line            =   rsl.line_num            -- ���הԍ�
      AND   rsl.shipment_header_id  =   rt.shipment_header_id   -- �������ID
      AND   rsl.shipment_line_id    =   rt.shipment_line_id     -- ������ד���ID
      AND   rt.transaction_type     =   cv_dest_type_deliver    -- ����^�C�v
      AND   itp.item_id             =   ilm.item_id             -- �i��ID
      AND   itp.lot_id              =   ilm.lot_id              -- ���b�gID
      AND   rsl.po_line_id          =   pla.po_line_id          -- ��������ID
      GROUP BY  itp.doc_type        -- �����^�C�v
              , itp.doc_id          -- ����ID
              , ximv.item_id        -- �i��ID
              , ximv.item_no        -- �i�ڃR�[�h
              , ilm.lot_id          -- ���b�gID
              , ilm.lot_no          -- ���b�gNo
              , pla.unit_price      -- �����P��
      UNION ALL
      SELECT  itc.doc_type          doc_type                    -- �����^�C�v
            , itc.doc_id            doc_id                      -- ����ID
            , ximv2.item_id         item_id                     -- �i��ID
            , ximv2.item_no         item_no                     -- �i�ڃR�[�h
            , ilm2.lot_id           lot_id                      -- ���b�gID
            , ilm2.lot_no           lot_no                      -- ���b�gNo
            , SUM(itc.trans_qty)    trans_qty                   -- ����
            , lcad.adjustment_cost  price                       -- ���������P��
      FROM    ic_tran_cmp                   itc                 -- �����݌Ƀg�����U�N�V����
            , xxcmn_item_mst_v              ximv2               -- OPM�i�ڏ��View
            , gmf_lot_cost_adjustments      lca                 -- ���b�g��������
            , gmf_lot_cost_adjustment_dtls  lcad                -- ���b�g������������
            , ic_lots_mst                   ilm2                -- OPM���b�g�}�X�^
            , sy_reas_cds_vl                srcv                -- ���R�R�[�h
      WHERE itc.doc_type              =   cv_doc_type_adji      -- �����^�C�v�F�I������
      AND   srcv.reason_desc1         =   cv_reason_cd_hamaoka  -- �K�p�F�l�����
      AND   itc.reason_code           =   srcv.reason_code      -- ���R�R�[�h
      AND   itc.trans_date            >=  gd_opening_date       -- �����
      AND   itc.item_id               =   ximv2.item_id         -- �i��ID
      AND   ximv2.cost_manage_code    =   cv_zero               -- �����Ǘ��敪�F0
      AND   itc.item_id               =   ilm2.item_id          -- �i��ID
      AND   itc.lot_id                =   ilm2.lot_id           -- ���b�gID
      AND   itc.item_id               =   lca.item_id           -- �i��ID
      AND   itc.lot_id                =   lca.lot_id            -- ���b�gID
      AND   lca.adjustment_id         =   lcad.adjustment_id    -- ���b�g��������ID
      GROUP BY  itc.doc_type          -- �����^�C�v
              , itc.doc_id            -- ����ID
              , ximv2.item_id         -- �i��ID
              , ximv2.item_no         -- �i�ڃR�[�h
              , ilm2.lot_id           -- ���b�gID
              , ilm2.lot_no           -- ���b�gNo
              , lcad.adjustment_cost  -- ���������P��
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================================
    -- �w���A�l������f�[�^��PL/SQL�\�ɃZ�b�g
    -- ========================================
    << get_data_cur >>
    FOR loop_cnt IN ins_data_cur LOOP
--
      -- ���ʂ�0�̏ꍇ�͎�荞�܂Ȃ�
      IF (loop_cnt.trans_qty > 0) THEN
--
        -- �f�[�^�J�E���g
        ln_data_cnt :=  ln_data_cnt + 1;
--
        -- �l�Z�b�g
        gt_doc_type_ins_tab(ln_data_cnt)    := loop_cnt.doc_type;   -- �����^�C�v
        gt_doc_id_ins_tab(ln_data_cnt)      := loop_cnt.doc_id;     -- ����ID
        gt_item_id_ins_tab(ln_data_cnt)     := loop_cnt.item_id;    -- �i��ID
        gt_item_code_ins_tab(ln_data_cnt)   := loop_cnt.item_no;    -- �i�ڃR�[�h
        gt_lot_id_ins_tab(ln_data_cnt)      := loop_cnt.lot_id;     -- ���b�gID
        gt_lot_num_ins_tab(ln_data_cnt)     := loop_cnt.lot_no;     -- ���b�gNo
        gt_trans_qty_ins_tab(ln_data_cnt)   := loop_cnt.trans_qty;  -- ����
        gt_unit_price_ins_tab(ln_data_cnt)  := loop_cnt.price;      -- �����P��/���������P��
--
      END IF;
--
    END LOOP get_data_cur;
--
    IF ( ln_data_cnt > 0 ) THEN
      -- �f�[�^�J�E���g�𐬌��f�[�^�J�E���g�ɃZ�b�g
      gn_normal_cnt :=  ln_data_cnt;
    ELSE
      -- �����Ώۃ��R�[�h��0���̏ꍇ
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- ���W���[�������́FXXCMN �}�X�^�E�o������
                   ,gv_msg_xxcmn10036   -- ���b�Z�[�W�FAPP-XXCMN-10036 �f�[�^�擾�G���[
                   ),1,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ins_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : �݌Ƀf�[�^���o�E�o�^����(A-3)
   ***********************************************************************************/
  PROCEDURE ins_table_batch(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_table_batch'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================
    -- �o�^�f�[�^�擾����
    -- =====================================
    get_ins_data(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �o�^�f�[�^�擾�������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- �ꊇ�o�^����
    -- =====================================
    FORALL ln_cnt IN 1..gt_doc_type_ins_tab.COUNT
      INSERT INTO xxcmn_txn_lot_cost(
          doc_type
        , doc_id
        , item_id
        , item_code
        , lot_id
        , lot_num
        , trans_qty
        , unit_price
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
      ) VALUES (
          gt_doc_type_ins_tab(ln_cnt)           -- �����^�C�v
        , gt_doc_id_ins_tab(ln_cnt)             -- ����ID
        , gt_item_id_ins_tab(ln_cnt)            -- �i��ID
        , gt_item_code_ins_tab(ln_cnt)          -- �i�ڃR�[�h
        , gt_lot_id_ins_tab(ln_cnt)             -- ���b�gID
        , gt_lot_num_ins_tab(ln_cnt)            -- ���b�gNo
        , NVL(gt_trans_qty_ins_tab(ln_cnt), 0)  -- �������
        , NVL(gt_unit_price_ins_tab(ln_cnt), 0) -- �P��
        , FND_GLOBAL.USER_ID                    -- �쐬��
        , SYSDATE                               -- �쐬��
        , FND_GLOBAL.USER_ID                    -- �ŏI�X�V��
        , SYSDATE                               -- �ŏI�X�V��
        , FND_GLOBAL.LOGIN_ID                   -- �ŏI�X�V���O�C��
        , FND_GLOBAL.CONC_REQUEST_ID            -- �v��ID
        , FND_GLOBAL.PROG_APPL_ID               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , FND_GLOBAL.CONC_PROGRAM_ID            -- �R���J�����g�E�v���O����ID
        , SYSDATE                               -- �v���O�����X�V��
      );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : �f�[�^�_���v�擾����
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxcmn_txn_lot_cost IN  xxcmn_txn_lot_cost%ROWTYPE,  
                                                -- ����ʃ��b�g�ʌ����i�A�h�I���j
    ov_dump               OUT NOCOPY VARCHAR2,  -- �f�[�^�_���v������
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_dump'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �f�[�^�_���v�쐬
    -- ===============================
    ov_dump :=  ir_xxcmn_txn_lot_cost.doc_type            -- �����^�C�v
                || gv_msg_comma ||  
                TO_CHAR(ir_xxcmn_txn_lot_cost.doc_id)     -- ����ID
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.item_id)    -- �i��ID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.item_code           -- �i�ڃR�[�h
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.lot_id)     -- ���b�gID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.lot_num             -- ���b�gNO
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.trans_qty)  -- �������
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.unit_price) -- �P��
                ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : put_success_dump
   * Description      : �����f�[�^�_���v�o�͏���
   ***********************************************************************************/
  PROCEDURE put_success_dump(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_success_dump'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
    lv_dump VARCHAR2(5000);  -- �f�[�^�_���v
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    ins_data_rec  xxcmn_txn_lot_cost%ROWTYPE; -- ����ʃ��b�g�ʌ����i�A�h�I���j�^���R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                 gv_xxcmn               -- ���W���[�������́FXXCMN ����
                ,gv_msg_xxcmn00005      -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    << success_dump_set_loop >>
    FOR ln_rec_cnt IN 1..gt_doc_type_ins_tab.COUNT LOOP
--
      -- =============================
      -- �_���v�p���R�[�h�ɃZ�b�g
      -- =============================
      ins_data_rec.doc_type   := gt_doc_type_ins_tab(ln_rec_cnt);    -- �����^�C�v
      ins_data_rec.doc_id     := gt_doc_id_ins_tab(ln_rec_cnt);      -- ����ID
      ins_data_rec.item_id    := gt_item_id_ins_tab(ln_rec_cnt);     -- �i��ID
      ins_data_rec.item_code  := gt_item_code_ins_tab(ln_rec_cnt);   -- �i�ڃR�[�h
      ins_data_rec.lot_id     := gt_lot_id_ins_tab(ln_rec_cnt);      -- ���b�gID
      ins_data_rec.lot_num    := gt_lot_num_ins_tab(ln_rec_cnt);     -- ���b�gNo
      ins_data_rec.trans_qty  := gt_trans_qty_ins_tab(ln_rec_cnt);   -- ����
      ins_data_rec.unit_price := gt_unit_price_ins_tab(ln_rec_cnt);  -- �P��
--
      -- =============================
      -- �f�[�^�_���v�擾����
      -- =============================
      get_data_dump(
          ir_xxcmn_txn_lot_cost => ins_data_rec
        , ov_dump               => lv_dump
        , ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
      );
      -- �f�[�^�_���v�擾�������G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- �����f�[�^���o��
      -- =============================
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_set_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_success_dump;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �o�^�pPL/SQL�\������
    gt_doc_type_ins_tab.DELETE;   -- �����^�C�v
    gt_doc_id_ins_tab.DELETE;     -- ����ID
    gt_item_id_ins_tab.DELETE;    -- �i��ID
    gt_item_code_ins_tab.DELETE;  -- �i�ڃR�[�h
    gt_lot_id_ins_tab.DELETE;     -- ���b�gID
    gt_lot_num_ins_tab.DELETE;    -- ���b�gNo
    gt_trans_qty_ins_tab.DELETE;  -- �������
    gt_unit_price_ins_tab.DELETE; -- �P��
--
    -- =======================================
    -- A-1.����ʃ��b�g�ʌ����e�[�u���폜����
    -- =======================================
    del_table_data(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- A-2.�݌ɃI�[�v�����Ԏ擾����
    -- =======================================
    get_opening_period(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- A-3.�݌Ƀf�[�^���o�E�o�^����
    -- =======================================
    ins_table_batch(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �݌Ƀf�[�^���o�E�o�^�������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- �����f�[�^�_���v�o�͏���
    -- =======================================
    put_success_dump(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �����f�[�^�_���v�o�͏������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf  OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode OUT NOCOPY VARCHAR2   --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn790001c;
/
