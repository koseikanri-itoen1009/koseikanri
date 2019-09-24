CREATE OR REPLACE PACKAGE BODY xxpo780002c
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : xxpo780002c(spec)
 * Description      : ���������L���x�����E�m�F��CSV�o��
 * MD.050/070       : �����Y�؏����i�L���x�����E�jIssue1.0  (T_MD050_BPO_780)
 *                    ���������L���x�����E�m�F��CSV�o��     (T_MD070_BPO_78B)
 * Version          : 1.0
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  init                       ��������(A-1)
 *  get_proc_date              �����f�[�^�擾(A-2)
 *  data_output                �f�[�^�o��(A-3)
 *  del_proc_date              �����f�[�^�폜(A-4)
 *  submain                    ���C�������v���V�[�W��
 *  main                       �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/09/10    1.0  N.Abe             �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo780002c';   -- �p�b�P�[�W��
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO';             -- �A�v���P�[�V�����iXXPO�j
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  ------------------------------
  -- �O���[�o���ϐ�
  ------------------------------
  gv_csv_head             fnd_new_messages.message_text%TYPE;   -- ���o���s
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- *** �O���[�o���E�J�[�\��
    CURSOR cur_main_data(
      in_request_id       NUMBER
    )
    IS
      SELECT xiw.vendor_name      AS  vendor_name       -- ����於
            ,xiw.zip              AS  zip               -- �X�֔ԍ�
            ,xiw.address          AS  address           -- �Z��
            ,xiw.arrival_date     AS  arrival_date      -- ���t
            ,xiw.slip_num         AS  slip_num          -- �`�[No
            ,xiw.lot_no           AS  lot_no            -- ���b�gNo
            ,xiw.dept_name        AS  dept_name         -- �����Ǘ�����
            ,xiw.item_class_name  AS  item_class_name   -- �i�ڋ敪�i���́j
            ,xiw.item_code        AS  item_code         -- �i�ڃR�[�h
            ,xiw.item_name        AS  item_name         -- �i�ږ���
            ,xiw.quantity         AS  quantity          -- ����
            ,xiw.unit_price       AS  unit_price        -- �P��
            ,xiw.amount           AS  amount            -- �Ŕ����z
            ,xiw.tax              AS  tax               -- ����Ŋz
            ,xiw.tax_type         AS  tax_type          -- �ŋ敪
            ,xiw.tax_include      AS  tax_include       -- �ō����z
            ,xiw.yusyo_year_month AS  yusyo_data        -- �L���N��
      FROM   xxpo_invoice_work  xiw
      WHERE  xiw.request_id = in_request_id
      ORDER BY xiw.vendor_code          -- �����R�[�h
              ,xiw.item_class           -- �i�ڋ敪
              ,xiw.arrival_date         -- ���ד�
              ,xiw.item_code            -- �i�ڃR�[�h
    ;
--
    rec_main_date   cur_main_data%ROWTYPE;
--
  -- CSV�o�͗p�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
    vendor_name       xxpo_invoice_work.vendor_name%TYPE      -- ����於
   ,zip               xxpo_invoice_work.zip%TYPE              -- �X�֔ԍ�
   ,address           xxpo_invoice_work.address%TYPE          -- �Z��
   ,arrival_date      xxpo_invoice_work.arrival_date%TYPE     -- ���t
   ,slip_num          xxpo_invoice_work.slip_num%TYPE         -- �`�[No
   ,lot_no            xxpo_invoice_work.lot_no%TYPE           -- ���b�gNo
   ,dept_name         xxpo_invoice_work.dept_name%TYPE        -- �����Ǘ�����
   ,item_class_name   xxpo_invoice_work.item_class_name%TYPE  -- �i�ڋ敪�i���́j
   ,item_code         xxpo_invoice_work.item_code%TYPE        -- �i�ڃR�[�h
   ,item_name         xxpo_invoice_work.item_name%TYPE        -- �i�ږ���
   ,quantity          xxpo_invoice_work.quantity%TYPE         -- ����
   ,unit_price        xxpo_invoice_work.unit_price%TYPE       -- �P��
   ,amount            xxpo_invoice_work.amount%TYPE           -- �Ŕ����z
   ,tax               xxpo_invoice_work.tax%TYPE              -- ����Ŋz
   ,tax_type          xxpo_invoice_work.tax_type%TYPE         -- �ŋ敪
   ,tax_include       xxpo_invoice_work.tax_include%TYPE      -- �ō����z
   ,yusyo_date        xxpo_invoice_work.yusyo_year_month%TYPE -- �L���N��
  ) ;
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  gt_main_data    tab_data_type_dtl;
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_data_cnt           NUMBER := 0;   -- �f�[�^�����擾�p
    lv_err_code           VARCHAR2(100); -- �G���[�R�[�h�i�[�p
    lv_token_name1        VARCHAR2(100);      -- ���b�Z�[�W�g�[�N�����P
    lv_token_name2        VARCHAR2(100);      -- ���b�Z�[�W�g�[�N�����Q
    lv_token_value1       VARCHAR2(100);      -- ���b�Z�[�W�g�[�N���l�P
    lv_token_value2       VARCHAR2(100);      -- ���b�Z�[�W�g�[�N���l�Q
--
    -- *** ���[�J���J�[�\�� ***
--
    -- *** ���[�J�����R�[�h ***
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --========================================
    -- 1.���o���s�擾
    --========================================
    gv_csv_head := xxccp_common_pkg.get_msg(
                     iv_application  => gc_application_po         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => 'APP-XXPO-40052'          -- ���b�Z�[�W�R�[�h
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_proc_data
   * Description      : �����f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_proc_data(
    in_request_id IN  NUMBER                    -- 01.�v��ID
   ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_proc_data'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_main_data(
      in_request_id    -- �v��ID
    );
    -- �o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO gt_main_data;
    -- �J�[�\���N���[�Y
    CLOSE cur_main_data;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_proc_data;
--
  /**********************************************************************************
   * Procedure Name   : data_output
   * Description      : �f�[�^�o��(A-3)
   ***********************************************************************************/
  PROCEDURE data_output(
    ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_output'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***
    cv_delimit    CONSTANT VARCHAR2(10) := ',';                   -- ��؂蕶��
    cv_enclosed   CONSTANT VARCHAR2(2)  := '"';                   -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    lv_line_data           VARCHAR2(5000);                        -- OUTPUT�f�[�^�ҏW�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���o���̏o��
    ------------------------------------------
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_csv_head
    );
    ------------------------------------------
    -- �f�[�^�o��
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      --�f�[�^��ҏW
      lv_line_data :=     cv_enclosed || gt_main_data(i).vendor_name                            || cv_enclosed  -- ����於
         || cv_delimit || cv_enclosed || gt_main_data(i).zip                                    || cv_enclosed  -- �X�֔ԍ�
         || cv_delimit || cv_enclosed || gt_main_data(i).address                                || cv_enclosed  -- �Z��
         || cv_delimit || cv_enclosed || TO_CHAR(gt_main_data(i).arrival_date, 'YYYY/MM/DD')    || cv_enclosed  -- ���t
         || cv_delimit || cv_enclosed || gt_main_data(i).yusyo_date                             || cv_enclosed  -- �L���N��
         || cv_delimit || cv_enclosed || gt_main_data(i).slip_num                               || cv_enclosed  -- �`�[No
         || cv_delimit || cv_enclosed || gt_main_data(i).lot_no                                 || cv_enclosed  -- ���b�gNo
         || cv_delimit || cv_enclosed || gt_main_data(i).dept_name                              || cv_enclosed  -- �����Ǘ�����
         || cv_delimit || cv_enclosed || gt_main_data(i).item_class_name                        || cv_enclosed  -- �i�ڋ敪�i���́j
         || cv_delimit || cv_enclosed || gt_main_data(i).item_code                              || cv_enclosed  -- �i�ڃR�[�h
         || cv_delimit || cv_enclosed || gt_main_data(i).item_name                              || cv_enclosed  -- �i�ږ���
         || cv_delimit ||                gt_main_data(i).quantity                                               -- ����
         || cv_delimit ||                gt_main_data(i).unit_price                                             -- �P��
         || cv_delimit ||                gt_main_data(i).amount                                                 -- �Ŕ����z
         || cv_delimit ||                gt_main_data(i).tax                                                    -- ����Ŋz
         || cv_delimit || cv_enclosed || gt_main_data(i).tax_type                               || cv_enclosed  -- �ŋ敪
         || cv_delimit ||                gt_main_data(i).tax_include                                            -- �ō����z
      ;
      --�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP data_output;
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
  END data_output;
--
  /**********************************************************************************
   * Procedure Name   : del_proc_data
   * Description      : �����f�[�^�폜(A-4)
   ***********************************************************************************/
  PROCEDURE del_proc_data(
    in_request_id IN  NUMBER                    -- 01.�v��ID
   ,ov_errbuf     OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_proc_data'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^�폜
    -- ====================================================
    DELETE xxpo_invoice_work
    WHERE  request_id = in_request_id
    ;
--
  EXCEPTION
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
  END del_proc_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_request_id         IN     NUMBER           -- 01 : �v��ID
   ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000);                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- =====================================================
    -- A-1.��������
    -- =====================================================
    init(
      ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- A-2.�����f�[�^�擾
    -- =====================================================
    get_proc_data(
      in_request_id     => in_request_id      -- 01.�v��ID
     ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- A-3.CSV�f�[�^�o��
    -- ==================================================
    data_output(
      ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- A-4.�����f�[�^�폜
    -- ==================================================
    del_proc_data(
      in_request_id     => in_request_id      -- 01.�v��ID
     ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
--
  EXCEPTION
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
   ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
   ,in_request_id         IN     NUMBER           -- 01 : �v��ID
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000);      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_message_code         VARCHAR2(100);
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
      in_request_id     => in_request_id      -- 01 : �v��ID
     ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �I������(A-5)
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    IF ( lv_retcode = gv_status_error ) THEN
      -- �G���[����
      gn_error_cnt := 1;
--
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = gv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = gv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = gv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo780002c;
/