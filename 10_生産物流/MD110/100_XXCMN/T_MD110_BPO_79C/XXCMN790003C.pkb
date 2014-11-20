CREATE OR REPLACE PACKAGE BODY xxcmn790003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790003c(body)
 * Description      : ���d���όv�Z����
 * MD.050           : ���b�g�ʎ��ی����v�Z T_MD050_BPO_790
 * MD.070           : ���d���όv�Z���� T_MD070_BPO_79C
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_table_data         ���b�g�ʌ����e�[�u���폜����(C-1)
 *  get_lot_cost           ���b�g�ʌ����f�[�^���o����(C-2)
 *                         ���b�g�ʌ����f�[�^�ҏW����(C-3)
 *  ins_table_batch        ���b�g�ʌ����f�[�^�o�^����(C-4)
 *  get_data_dump          �f�[�^�_���v�擾����
 *  put_success_dump       �����f�[�^�_���v�o�͏���
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/6      1.0   R.Matusita       �V�K�쐬
 *  2008/12/02    1.1   H.Marushita      ���ʃ[���̎���ʃ��b�g�����𒊏o�ΏۊO�Ƃ���B
 *  2008/12/05    1.2   H.Marushita      �{��435�Ή�
 *  2008/12/19    1.3   H.Marushita      �݌ɒ����p�ɍX�V�Ɠo�^���s���悤�ɏC��
 *  2009/01/14    1.4   H.Marushita      ���b�g�}�X�^�̒P���ύX���f�����̌�����
 *  2013/01/08    1.5   M.Kitajima       ���b�g�ʌ����A�h�I���̒P���X�V�����̌�����
 *                                       (E_�{�ғ�_10355)
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
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790003c';  -- �p�b�P�[�W��
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
-- 2008/12/19 ADD S
-- ���b�g�}�X�^�P�����f�p
  TYPE xlc_item_id_ttype    IS TABLE OF xxcmn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �i��ID
  TYPE xlc_lot_id_ttype     IS TABLE OF xxcmn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ���b�gID
  TYPE xlc_trans_qty_ttype  IS TABLE OF xxcmn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �������
  TYPE xlc_unit_price_ttype IS TABLE OF xxcmn_lot_cost.unit_ploce%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �P��
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
  TYPE unit_price_flag_ttype IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;    -- �X�V�t���O
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
-- 
-- ���b�g�}�X�^�P�����f�pPL/SQL�\
  gt_xlc_item_id_tab    xlc_item_id_ttype;
  gt_xlc_lot_id_tab     xlc_lot_id_ttype;
  gt_xlc_trans_qty_tab  xlc_trans_qty_ttype;
  gt_xlc_unit_price_tab xlc_unit_price_ttype;
-- 2008/12/19 ADD E
--
  -- �o�^�pPL/SQL�\
  gt_item_id_ins_tab    item_id_ttype;      -- �i��ID
  gt_item_code_ins_tab  item_code_ttype;    -- �i�ڃR�[�h
  gt_lot_id_ins_tab     lot_id_ttype;       -- ���b�gID
  gt_lot_num_ins_tab    lot_num_ttype;      -- ���b�gNo
  gt_trans_qty_ins_tab  trans_qty_ttype;    -- �������
  gt_unit_price_ins_tab unit_price_ttype;   -- �P��
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
  gt_unit_price_ins_flag_tbl unit_price_flag_ttype; --�P���X�V�t���O
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
  -- �X�V�pPL/SQL�\
  gt_item_id_upd_tab    item_id_ttype;      -- �i��ID
  gt_lot_id_upd_tab     lot_id_ttype;       -- ���b�gID
  gt_trans_qty_upd_tab  trans_qty_ttype;    -- �������
  gt_unit_price_upd_tab unit_price_ttype;   -- �P��
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
  gt_unit_price_upd_flag_tbl unit_price_flag_ttype; --�P���X�V�t���O
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
  -- ���̓f�[�^�_���v�pPL/SQL�\�^
  TYPE msg_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �݌ɃI�[�v������
--2013/01/08 DEL AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
--  gv_opening_date     DATE;
--2013/01/08 DEL AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
  -- OPM�݌ɃJ�����_�̒��ߒ���
  gt_close_yyyymm     XXINV_STC_INVENTORY_MONTH_STCK.INVENT_YM%TYPE;
                                              -- ���߂̒��ߍς̔N��
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
  gn_ins_cnt          NUMBER DEFAULT 0;       -- �o�^����
  gn_upd_cnt          NUMBER DEFAULT 0;       -- �X�V����
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : ���b�g�ʌ����e�[�u���폜����(C-1)
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
      FROM    xxcmn_lot_cost xtlc   -- ���b�g�ʌ����i�A�h�I���j
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
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn          -- ���W���[�������́FXXCMN �}�X�^�E�o������
                     ,gv_msg_xxcmn10146 -- ���b�Z�[�W�F���b�N�擾�G���[
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- ���b�g�ʌ����i�A�h�I���j�폜
    -- =====================================
    DELETE FROM xxcmn_lot_cost xtlc   -- ���b�g�ʌ����i�A�h�I���j
    WHERE NOT EXISTS
    (SELECT 'X'
     FROM ic_lots_mst ilm
     WHERE xtlc.item_id = ilm.item_id
     AND   xtlc.lot_id  = ilm.lot_id)  -- OPM���b�g�}�X�^
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
   * Procedure Name   : get_lot_cost
   * Description      : ���b�g�ʌ����f�[�^���o����(C-2)
   *                  : ���b�g�ʌ����f�[�^�ҏW����(C-3)
   ***********************************************************************************/
  PROCEDURE get_lot_cost(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_cost'; -- �v���O������
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
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
    cv_update_flag      CONSTANT VARCHAR2(1) := '*';  --���b�g�}�X�^�̒P�����g�p�����ꍇ�Z�b�g����
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
    -- *** ���[�J���ϐ� ***
    ln_user_id          NUMBER;            -- ���O�C�����Ă��郆�[�U�[
    ln_login_id         NUMBER;            -- �ŏI�X�V���O�C��
    ln_conc_request_id  NUMBER;            -- �v��ID
    ln_prog_appl_id     NUMBER;            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id  NUMBER;            -- �R���J�����g�E�v���O����ID
    ln_loop_cnt         NUMBER;            -- ���[�v�J�[�\���ϐ�
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
    ln_data_cnt   NUMBER; -- �I�������݌Ƀe�[�u���̑��݃`�F�b�N�Ɏg�p
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �\���b�N�擾
    CURSOR get_tab_lock_cur
    IS
      SELECT  xlc.lot_id
      FROM    xxcmn_lot_cost xlc   -- ���b�g�ʌ����i�A�h�I���j
      FOR UPDATE NOWAIT
      ;
--      
-- 2008/12/19 ADD S
    -- �X�V�p
    -- ���b�g�}�X�^�Ƌ��z���ق����郍�b�g�ʎ��ی����̃f�[�^���X�V����
    CURSOR upd_lot_cost_date_cur
    IS
      SELECT  ilm.item_id               item_id
            , ilm.lot_id                lot_id
            , ilm.trans_cnt             trans_cnt
            , TO_NUMBER(ilm.attribute7) unit_price
      FROM 
            ic_lots_mst ilm
           ,ic_item_mst_b imb
           ,xxcmn_lot_cost xlc
      WHERE ilm.lot_id > 0  -- �f�t�H���g���b�g������
        AND TO_NUMBER(NVL(ilm.attribute7,0)) <> 0 -- ���ی������ݒ肳��Ă������
        AND ilm.item_id = imb.item_id
        AND imb.attribute15 = '0' -- ���ی���
        AND imb.lot_ctl     = '1' -- ���b�g�Ǘ��i
        AND ilm.item_id = xlc.item_id
        AND ilm.lot_id  = xlc.lot_id
        AND TO_NUMBER(NVL(ilm.attribute7,0)) <> NVL(xlc.UNIT_PLOCE,0)
      ;
-- 2008/12/19 ADD E
    -- �o�^�p
    -- ���b�g�ʌ����i�A�h�I���j�e�[�u���ɓ���i�ځE���ꃍ�b�g�̃f�[�^�����݂��Ȃ��f�[�^
    CURSOR ins_lot_data_cur
    IS
      SELECT  xtlc.item_id               item_id         -- �i��ID
            , xtlc.item_code             item_code       -- �i�ڃR�[�h
            , xtlc.lot_id                lot_id          -- ���b�gID
            , xtlc.lot_num               lot_num         -- ���b�gNo
            , SUM(NVL(xtlc.trans_qty,0)) trans_qty       -- �������
            , SUM(NVL(xtlc.unit_price,0)
                * NVL(xtlc.trans_qty,0)) price           -- �P��*���ʁi=������z�j
      FROM    xxcmn_txn_lot_cost xtlc                    -- ����ʃ��b�g�ʌ����i�A�h�I���j
      WHERE NOT EXISTS
      (SELECT 'X'
       FROM xxcmn_lot_cost xlc            -- ���b�g�ʌ����i�A�h�I���j
       WHERE xtlc.item_id   = xlc.item_id
       AND   xtlc.lot_id    = xlc.lot_id
      )
-- 2008/12/02 ADD START
      AND   xtlc.trans_qty > 0
-- 2008/12/02 ADD END
      GROUP BY xtlc.item_id, xtlc.item_code ,xtlc.lot_id ,xtlc.lot_num
      ;
--
    -- �X�V�p
    -- ���b�g�ʌ����i�A�h�I���j�e�[�u���ɓ���i�ځE���ꃍ�b�g�̃f�[�^�����݂���f�[�^
    CURSOR upd_lot_data_cur
    IS
      SELECT  xtlc.item_id               item_id   -- �i��ID
            , xtlc.lot_id                lot_id    -- ���b�gID
            , SUM(NVL(xtlc.trans_qty,0)) trans_qty -- �������
            , SUM(NVL(xtlc.unit_price,0)
                * NVL(xtlc.trans_qty,0)) price     -- �P��*���ʁi=������z�j
      FROM    xxcmn_txn_lot_cost xtlc              -- ����ʃ��b�g�ʌ����i�A�h�I���j
            , xxcmn_lot_cost xlc                   -- ���b�g�ʌ����i�A�h�I���j
      WHERE xtlc.item_id   = xlc.item_id
      AND   xtlc.lot_id    = xlc.lot_id
-- 2008/12/02 ADD START
      AND   xtlc.trans_qty > 0
-- 2008/12/02 ADD END
      GROUP BY xtlc.item_id, xtlc.item_code ,xtlc.lot_id ,xtlc.lot_num
      ;
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
   /**********************************************************************************
   * ���b�g�ʌ����f�[�^�ҏW����(C-3)
   ***********************************************************************************/
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
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn          -- ���W���[�������́FXXCMN �}�X�^�E�o������
                     ,gv_msg_xxcmn10146 -- ���b�Z�[�W�F���b�N�擾�G���[
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- ���ʍX�V���̎擾
    ln_user_id         := FND_GLOBAL.USER_ID;        -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id        := FND_GLOBAL.LOGIN_ID;       -- �ŏI�X�V���O�C��
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- �v��ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- �R���J�����g�E�v���O����ID
--
    -- ======================================
    -- �݌ɒ������쐬���b�g���ی������f
    -- ======================================
--2008/12/19 ADD S
    ln_loop_cnt := 0;
    <<upd_lot_cost_date_loop>>
    FOR loop_cnt IN upd_lot_cost_date_cur LOOP
--
      -- �f�[�^�J�E���g
      ln_loop_cnt :=  ln_loop_cnt + 1;
--
      -- �l�Z�b�g
      gt_xlc_item_id_tab(ln_loop_cnt)     := loop_cnt.item_id;              -- �i��ID
      gt_xlc_lot_id_tab(ln_loop_cnt)      := loop_cnt.lot_id;               -- ���b�gID
      gt_xlc_trans_qty_tab(ln_loop_cnt)   := loop_cnt.trans_cnt;            -- ����
      gt_xlc_unit_price_tab(ln_loop_cnt)  := loop_cnt.unit_price;           -- �P��
--
    END LOOP upd_lot_cost_date_loop;
--
    -- �ꊇ�X�V����
-- 2009/01/14 MOD S
--    FORALL ln_loop_cnt IN 1 .. gt_item_id_upd_tab.COUNT
--
    FORALL ln_loop_cnt IN 1 .. gt_xlc_item_id_tab.COUNT
--
-- 2009/01/14 MOD E
      -- ���b�g�ʎ��ی����}�X�^�X�V
      UPDATE xxcmn_lot_cost
      SET trans_qty               = gt_xlc_trans_qty_tab(ln_loop_cnt) -- �������
         ,unit_ploce              = gt_xlc_unit_price_tab(ln_loop_cnt)-- �P�� 
         ,last_updated_by         = ln_user_id                   -- �ŏI�X�V��
         ,last_update_date        = SYSDATE                      -- �ŏI�X�V��
         ,last_update_login       = ln_login_id                  -- �ŏI�X�V���O�C��
         ,request_id              = ln_conc_request_id           -- �v��ID
         ,program_application_id  = ln_prog_appl_id              -- �ݶ��āE��۸��сE���ع����ID
         ,program_id              = ln_conc_program_id           -- �R���J�����g�E�v���O����ID
         ,program_update_date     = SYSDATE                      -- �v���O�����X�V��
      WHERE item_id   = gt_xlc_item_id_tab(ln_loop_cnt)          -- �i��ID
      AND   lot_id    = gt_xlc_lot_id_tab(ln_loop_cnt);          -- ���b�gID
--2008/12/19 ADD E
--
        INSERT INTO xxcmn_lot_cost(
          item_id
        , item_code
        , lot_id
        , lot_num
        , trans_qty
        , unit_ploce
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        ) SELECT 
         iim.item_id
        ,iim.item_no
        ,ilm.lot_id
        ,ilm.lot_no
        ,ilm.trans_cnt
        ,to_number(ilm.attribute7) AS unit_price
        ,ln_user_id                             -- �쐬��
        ,SYSDATE                                -- �쐬��
        ,ln_user_id                             -- �ŏI�X�V��
        ,SYSDATE                                -- �ŏI�X�V��
        ,ln_login_id                            -- �ŏI�X�V���O�C��
        ,ln_conc_request_id                     -- �v��ID
        ,ln_prog_appl_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,ln_conc_program_id                     -- �R���J�����g�E�v���O����ID
        ,SYSDATE                                -- �v���O�����X�V��
        FROM 
         ic_lots_mst ilm
        ,ic_item_mst_b iim
        WHERE ilm.lot_id > 0  -- �f�t�H���g���b�g������
        AND TO_NUMBER(NVL(ilm.attribute7,0)) <> 0 -- ���ی������ݒ肳��Ă������
        AND iim.item_id = ilm.item_id
        AND iim.attribute15 = '0'
        AND iim.lot_ctl     = '1'
        AND NOT EXISTS (
          SELECT 1 
          FROM  xxcmn_lot_cost xlc
          WHERE xlc.item_id = ilm.item_id
          AND   xlc.lot_id  = ilm.lot_id
        );
--
    -- ========================================
    -- �o�^�p����ʌ����f�[�^��PL/SQL�\�ɃZ�b�g
    -- ========================================
    <<ins_data_loop>>
    FOR loop_cnt IN ins_lot_data_cur LOOP
--
      -- �f�[�^�J�E���g
      gn_ins_cnt :=  gn_ins_cnt + 1;
      -- �����������J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �l�Z�b�g
      gt_item_id_ins_tab(gn_ins_cnt)     := loop_cnt.item_id;              -- �i��ID
      gt_item_code_ins_tab(gn_ins_cnt)   := loop_cnt.item_code;            -- �i�ڃR�[�h
      gt_lot_id_ins_tab(gn_ins_cnt)      := loop_cnt.lot_id;               -- ���b�gID
      gt_lot_num_ins_tab(gn_ins_cnt)     := loop_cnt.lot_num;              -- ���b�gNo
      gt_trans_qty_ins_tab(gn_ins_cnt)   := loop_cnt.trans_qty;            -- ����
      IF ( loop_cnt.trans_qty = 0 ) THEN
        gt_unit_price_ins_tab(gn_ins_cnt) := 0;                            -- ������z
      ELSE
        gt_unit_price_ins_tab(gn_ins_cnt) := ROUND(loop_cnt.price
                                                 / loop_cnt.trans_qty, 2); -- ������z/����
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
      -- �X�V�t���O�͕K�v�Ȃ����_���v�o�͋��ʊ֐���INPUT�p�����[�^�Ƃ��Ďg�p����ׁA�_�~�[�œ���
      gt_unit_price_ins_flag_tbl(gn_ins_cnt) := NULL;
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
    END LOOP ins_data_loop;
--
    -- ========================================
    -- �X�V�p����ʌ����f�[�^��PL/SQL�\�ɃZ�b�g
    -- ========================================
    <<upd_data_loop>>
    FOR loop_cnt IN upd_lot_data_cur LOOP
      -- �f�[�^�J�E���g
      gn_upd_cnt :=  gn_upd_cnt + 1;
      -- �����������J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �l�Z�b�g
      gt_item_id_upd_tab(gn_upd_cnt)     := loop_cnt.item_id;              -- �i��ID
      gt_lot_id_upd_tab(gn_upd_cnt)      := loop_cnt.lot_id;               -- ���b�gID
      gt_trans_qty_upd_tab(gn_upd_cnt)   := loop_cnt.trans_qty;            -- ����
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
      gt_unit_price_upd_flag_tbl(gn_upd_cnt) := NULL;                      -- �P���X�V�t���O
      -- �I�������݌Ƀe�[�u�����Q�Ƃ������������̃��b�g���̔��f�����{
      SELECT /*+ INDEX(xsims XXINV_SIMS_N04) */
        COUNT(1) AS COUNT
      INTO   ln_data_cnt
      FROM   xxinv_stc_inventory_month_stck xsims
      WHERE  xsims.item_id          = loop_cnt.item_id
      AND    xsims.lot_id           = loop_cnt.lot_id
      AND    xsims.invent_ym       <= gt_close_yyyymm
      AND    ROWNUM               = 1;
      IF ( ln_data_cnt = 0 ) THEN
        -- �I�������݌Ƀe�[�u���̒��ߒ��ߌ��ȉ��ɖ����݂̏ꍇ�͓����Ƀ��b�g������
        IF ( loop_cnt.trans_qty = 0 ) THEN
          gt_unit_price_upd_tab(gn_upd_cnt) := 0;                            -- ������z
        ELSE
          gt_unit_price_upd_tab(gn_upd_cnt) := ROUND(loop_cnt.price
                                                   / loop_cnt.trans_qty, 2); -- ������z/����
        END IF;
      ELSE
        -- �I�������݌Ƀe�[�u���̒��ߒ��ߌ��ȉ��ɑ��݂���ꍇ�͒P���ύX�Ȃ�
        IF ( loop_cnt.trans_qty = 0 ) THEN
          gt_unit_price_upd_tab(gn_upd_cnt) := 0;                            -- ������z
        ELSE
          SELECT /*+ INDEX(ilm IC_LOTS_MST_PK) */
            TO_NUMBER(NVL(ilm.attribute7,'0')) AS unit_price
          INTO   gt_unit_price_upd_tab(gn_upd_cnt)                           -- ���b�g�}�X�^�̒P���ݒ�
          FROM   ic_lots_mst ilm
          WHERE  ilm.item_id = loop_cnt.item_id
          AND    ilm.lot_id  = loop_cnt.lot_id;
          --�P���X�V�̓��b�g�}�X�^�̒P�����擾����ׁA�X�V���Ȃ�
          gt_unit_price_upd_flag_tbl(gn_upd_cnt) := cv_update_flag;          -- �X�V
        END IF;
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--2013/01/08 DEL AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
--      IF ( loop_cnt.trans_qty = 0 ) THEN
--        gt_unit_price_upd_tab(gn_upd_cnt) := 0;                            -- ������z
--      ELSE
--        gt_unit_price_upd_tab(gn_upd_cnt) := ROUND(loop_cnt.price
--                                                 / loop_cnt.trans_qty, 2); -- ������z/����
--      END IF;
--2013/01/08 DEL AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
    END LOOP upd_data_loop;
--
    IF ( gn_ins_cnt + gn_upd_cnt > 0 ) THEN
      -- �f�[�^�J�E���g�𐬌��f�[�^�J�E���g�ɃZ�b�g
      gn_normal_cnt := gn_ins_cnt + gn_upd_cnt;
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
  END get_lot_cost;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : ���b�g�ʌ����f�[�^�o�^����(C-4)
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
    ln_user_id          NUMBER;            -- ���O�C�����Ă��郆�[�U�[
    ln_login_id         NUMBER;            -- �ŏI�X�V���O�C��
    ln_conc_request_id  NUMBER;            -- �v��ID
    ln_prog_appl_id     NUMBER;            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id  NUMBER;            -- �R���J�����g�E�v���O����ID
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
    -- ���ʍX�V���̎擾
    ln_user_id         := FND_GLOBAL.USER_ID;        -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id        := FND_GLOBAL.LOGIN_ID;       -- �ŏI�X�V���O�C��
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- �v��ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- �R���J�����g�E�v���O����ID
--
    -- =====================================
    -- �ꊇ�o�^����
    -- =====================================
    FORALL ln_cnt IN 1..gt_item_id_ins_tab.COUNT
      INSERT INTO xxcmn_lot_cost(
          item_id
        , item_code
        , lot_id
        , lot_num
        , trans_qty
        , unit_ploce
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
          gt_item_id_ins_tab(ln_cnt)            -- �i��ID
        , gt_item_code_ins_tab(ln_cnt)          -- �i�ڃR�[�h
        , gt_lot_id_ins_tab(ln_cnt)             -- ���b�gID
        , gt_lot_num_ins_tab(ln_cnt)            -- ���b�gNo
        , gt_trans_qty_ins_tab(ln_cnt)          -- �������
        , gt_unit_price_ins_tab(ln_cnt)         -- �P��
        ,ln_user_id                             -- �쐬��
        ,SYSDATE                                -- �쐬��
        ,ln_user_id                             -- �ŏI�X�V��
        ,SYSDATE                                -- �ŏI�X�V��
        ,ln_login_id                            -- �ŏI�X�V���O�C��
        ,ln_conc_request_id                     -- �v��ID
        ,ln_prog_appl_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,ln_conc_program_id                     -- �R���J�����g�E�v���O����ID
        ,SYSDATE);                              -- �v���O�����X�V��
--
    -- =====================================
    -- �ꊇ�X�V����
    -- =====================================
      FORALL ln_cnt IN 1 .. gt_item_id_upd_tab.COUNT
        -- �i�ڃ}�X�^�X�V(�\��t���OOFF)
        UPDATE xxcmn_lot_cost
        SET trans_qty               = gt_trans_qty_upd_tab(ln_cnt) -- �������
           ,unit_ploce              = gt_unit_price_upd_tab(ln_cnt)-- �P�� 
           ,last_updated_by         = ln_user_id                   -- �ŏI�X�V��
           ,last_update_date        = SYSDATE                      -- �ŏI�X�V��
           ,last_update_login       = ln_login_id                  -- �ŏI�X�V���O�C��
           ,request_id              = ln_conc_request_id           -- �v��ID
           ,program_application_id  = ln_prog_appl_id              -- �ݶ��āE��۸��сE���ع����ID
           ,program_id              = ln_conc_program_id           -- �R���J�����g�E�v���O����ID
           ,program_update_date     = SYSDATE                      -- �v���O�����X�V��
        WHERE item_id   = gt_item_id_upd_tab(ln_cnt)               -- �i��ID
        AND   lot_id    = gt_lot_id_upd_tab(ln_cnt);               -- ���b�gID
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
    ir_xxcmn_lot_cost     IN  xxcmn_lot_cost%ROWTYPE,  
                                                -- ����ʃ��b�g�ʌ����i�A�h�I���j
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
    iv_unit_price_flag    IN  VARCHAR2,         -- �X�V�t���O
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
    ov_dump               OUT NOCOPY VARCHAR2,  -- �f�[�^�_���v������
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2,  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    in_ins_upd_flg        IN  NUMBER)           -- �o�^�X�V�t���O(�o�^�F0�E�X�V�F1)
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
--
    IF ( in_ins_upd_flg =0 ) THEN
      -- �o�^��
      ov_dump :=  TO_CHAR(ir_xxcmn_lot_cost.item_id)    -- �i��ID
                  || gv_msg_comma ||
                  ir_xxcmn_lot_cost.item_code           -- �i�ڃR�[�h
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.lot_id)     -- ���b�gID
                  || gv_msg_comma ||
                  ir_xxcmn_lot_cost.lot_num             -- ���b�gNO
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.trans_qty)  -- �������
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.unit_ploce) -- �P��
                  ;
     ELSE
      -- �X�V��
      ov_dump :=  TO_CHAR(ir_xxcmn_lot_cost.item_id)    -- �i��ID
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.lot_id)     -- ���b�gID
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.trans_qty)  -- �������
                  || gv_msg_comma ||
                  TO_CHAR(ir_xxcmn_lot_cost.unit_ploce) -- �P��
                  ;
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
      -- �X�V�t���O��NOT NULL�̏ꍇ
      IF ( iv_unit_price_flag IS NOT NULL ) THEN
       ov_dump := ov_dump || gv_msg_comma ||
                             iv_unit_price_flag;
      END IF;
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
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
    in_ins_upd_flg NUMBER;   -- �o�^�X�V�t���O(�o�^�F0�E�X�V�F1)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    ins_data_rec  xxcmn_lot_cost%ROWTYPE; -- ���b�g�ʌ����i�A�h�I���j�^���R�[�h
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
    -- �o�^�f�[�^  
    << success_dump_ins_set_loop >>
    FOR ln_rec_cnt IN 1..gt_item_id_ins_tab.COUNT LOOP
--
      -- =============================
      -- �_���v�p���R�[�h�ɃZ�b�g
      -- =============================
      ins_data_rec.item_id    := gt_item_id_ins_tab(ln_rec_cnt);     -- �i��ID
      ins_data_rec.item_code  := gt_item_code_ins_tab(ln_rec_cnt);   -- �i�ڃR�[�h
      ins_data_rec.lot_id     := gt_lot_id_ins_tab(ln_rec_cnt);      -- ���b�gID
      ins_data_rec.lot_num    := gt_lot_num_ins_tab(ln_rec_cnt);     -- ���b�gNo
      ins_data_rec.trans_qty  := gt_trans_qty_ins_tab(ln_rec_cnt);   -- ����
      ins_data_rec.unit_ploce := gt_unit_price_ins_tab(ln_rec_cnt);  -- �P��
--
      -- =============================
      -- �f�[�^�_���v�擾����
      -- =============================
      get_data_dump(
          ir_xxcmn_lot_cost => ins_data_rec
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
        , iv_unit_price_flag    => gt_unit_price_ins_flag_tbl(ln_rec_cnt) -- �X�V�t���O
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
        , ov_dump               => lv_dump
        , ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
        , in_ins_upd_flg        => 0
      );
      -- �f�[�^�_���v�擾�������G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- �����f�[�^���o��
      -- =============================
      IF ( ln_rec_cnt = 1) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�i�o�^�f�[�^�j');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_ins_set_loop;
--
    -- �X�V�f�[�^
    << success_dump_upd_set_loop >>
    FOR ln_rec_cnt IN 1..gt_item_id_upd_tab.COUNT LOOP
--
      -- =============================
      -- �_���v�p���R�[�h�ɃZ�b�g
      -- =============================
      ins_data_rec.item_id    := gt_item_id_upd_tab(ln_rec_cnt);     -- �i��ID
      ins_data_rec.lot_id     := gt_lot_id_upd_tab(ln_rec_cnt);      -- ���b�gID
      ins_data_rec.trans_qty  := gt_trans_qty_upd_tab(ln_rec_cnt);   -- ����
      ins_data_rec.unit_ploce := gt_unit_price_upd_tab(ln_rec_cnt);  -- �P��
--
      -- =============================
      -- �f�[�^�_���v�擾����
      -- =============================
      get_data_dump(
          ir_xxcmn_lot_cost => ins_data_rec
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
        , iv_unit_price_flag    => gt_unit_price_upd_flag_tbl(ln_rec_cnt) -- �X�V�t���O
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
        , ov_dump               => lv_dump
        , ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
        , in_ins_upd_flg        => 1
      );
      -- �f�[�^�_���v�擾�������G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- �����f�[�^���o��
      -- =============================
      IF ( ln_rec_cnt = 1) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�i�X�V�f�[�^�j');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_upd_set_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gt_item_id_ins_tab.DELETE;    -- �i��ID
    gt_item_code_ins_tab.DELETE;  -- �i�ڃR�[�h
    gt_lot_id_ins_tab.DELETE;     -- ���b�gID
    gt_lot_num_ins_tab.DELETE;    -- ���b�gNo
    gt_trans_qty_ins_tab.DELETE;  -- �������
    gt_unit_price_ins_tab.DELETE; -- �P��
--
    -- �X�V�pPL/SQL�\������
    gt_item_id_upd_tab.DELETE;    -- �i��ID
    gt_lot_id_upd_tab.DELETE;     -- ���b�gID
    gt_trans_qty_upd_tab.DELETE;  -- �������
    gt_unit_price_upd_tab.DELETE; -- �P��
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
    gt_unit_price_ins_flag_tbl.DELETE; -- �P���X�V�t���O(INSERT)
    gt_unit_price_upd_flag_tbl.DELETE; -- �P���X�V�t���O(UPDATE)
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 START
    -- =======================================
    -- OPM�݌ɃJ�����_�̒��ߒ����擾
    -- =======================================
    gt_close_yyyymm := xxcmn_common_pkg.get_opminv_close_period;
--2013/01/08 ADD AUTHOR:M.Kitajima VER�F1.5 CONTENT:E_�{�ғ�_10355 END
--
    -- =======================================
    -- C-1.���b�g�ʌ����e�[�u���폜����
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
    -- C-2.���b�g�ʌ����f�[�^���o����(C-3.���b�g�ʌ����f�[�^�ҏW����)
    -- =======================================
    get_lot_cost(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- C-4.���b�g�ʌ����f�[�^�o�^����
    -- =======================================
    ins_table_batch(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���b�g�ʌ����f�[�^�o�^�������G���[�̏ꍇ
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
    errbuf        OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT NOCOPY VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
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
END xxcmn790003c;
/
