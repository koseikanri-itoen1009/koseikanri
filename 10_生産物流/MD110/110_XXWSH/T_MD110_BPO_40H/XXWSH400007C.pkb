CREATE OR REPLACE PACKAGE BODY xxwsh400007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400007c(BODY)
 * Description      : �o�׈˗����ߏ���
 * MD.050           : T_MD050_BPO_401_�o�׈˗�
 * MD.070           : �o�׈˗����ߏ��� T_MD070_BPO_40H
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  ship_tightening        �o�׈˗����ߏ���
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/4/10     1.0   R.Matusita       �V�K�쐬
 *  2008/5/19     1.1   Oracle �㌴���D  �����ύX�v��#80�Ή� �p�����[�^�u���_�v�ǉ�
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
  gn_all           CONSTANT NUMBER      := -999;
  gv_all           CONSTANT VARCHAR2(3) := 'ALL';
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
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxwsh400007c'; -- �p�b�P�[�W��
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';        -- ���W���[�����ȗ��FXXCMN�}�X�^����
  gv_cnst_msg_kbn   CONSTANT VARCHAR2(5)    := 'XXWSH';
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';
                                            -- ���b�Z�[�W�F���b�N�擾�G���[
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- ���b�Z�[�W�F�f�[�^�擾�G���[
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';
                                            -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
  gv_cnst_msg_null  CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11218';  -- �K�{�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_prop  CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11219';  -- �Ó����`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_fomt  CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11214';  -- �}�X�^�����G���[
  gv_cnst_msg_215   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11215';  -- ���ʊ֐��G���[
  gv_cnst_msg_216   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11216';  -- ���ʊ֐��x���I��
  gv_cnst_msg_222   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11222';  -- 
  gv_cnst_msg_224   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11225';  -- ����I���G���[���b�Z�[�W
--
  gn_status_error   CONSTANT NUMBER := 1;
  gv_line_feed      CONSTANT VARCHAR2(1)    := CHR(10); -- ���s�R�[�h;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_upd_cnt          NUMBER DEFAULT 0;      -- �X�V����
--
  gv_msg_kbn          CONSTANT VARCHAR2(5)  DEFAULT 'XXCMN';
  --�g�[�N��
  gv_tkn_api_name     CONSTANT VARCHAR2(15) DEFAULT 'API_NAME';
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_type_id         IN  VARCHAR2  DEFAULT NULL, -- �o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- �o�׌�
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- ���_
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- ���_�J�e�S��
    iv_lead_time_day         IN  VARCHAR2  DEFAULT NULL, -- ���Y����LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- �o�ɓ�
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- ����R�[�h�敪
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- �˗�No
    iv_tighten_class         IN  VARCHAR2  DEFAULT NULL, -- ���ߏ����敪
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- ���i�敪
    iv_tightening_program_id IN  VARCHAR2  DEFAULT NULL, -- ���߃R���J�����gID
    iv_instruction_dept      IN  VARCHAR2  DEFAULT NULL, -- ����
    ov_errbuf                OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    cv_tighten_class_1     VARCHAR2(1)   := '1'; -- ���ߏ����敪1:����
    cv_tighten_class_2     VARCHAR2(1)   := '2'; -- ���ߏ����敪2:��
    cv_tightening_status_chk_cla_1   VARCHAR2(1)    := '1'; -- ���߃X�e�[�^�X�`�F�b�N�敪1
    cv_callfrom_flg_1                VARCHAR2(1)    := '1'; -- �ďo���t���O1
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
    lv_cnst_msg       CONSTANT VARCHAR2(30)  := '���߃X�e�[�^�X�`�F�b�N�敪';
    lv_cnst_01        CONSTANT VARCHAR2(30)  := '�o�Ɍ`��ID';
    lv_cnst_03        CONSTANT VARCHAR2(30)  := '���Y����LT';
    lv_cnst_04        CONSTANT VARCHAR2(30)  := '�o�ɓ�';
    lv_cnst_05        CONSTANT VARCHAR2(30)  := '����R�[�h�敪';
    lv_cnst_06        CONSTANT VARCHAR2(30)  := '���ߏ����敪';
    lv_cnst_07        CONSTANT VARCHAR2(30)  := '���߃R���J�����gID';
    lv_cnst_08        CONSTANT VARCHAR2(30)  := '���i�敪';
    lv_cnst_09        CONSTANT VARCHAR2(30)  := '����';
    lv_cnst_10        CONSTANT VARCHAR2(30)  := '���̓p�����[�^�u�o�ɓ��v�̒l';
    lv_cnst_11        CONSTANT VARCHAR2(30)  := '�X�e�[�^�X�̍X�V';
    lv_cnst_12        CONSTANT VARCHAR2(30)  := '�o�׈˗����擾';
    lv_cnst_13        CONSTANT VARCHAR2(30)  := '���߃R���J�����gID';
    lv_cnst_14        CONSTANT VARCHAR2(30)  := '�o�Ɍ`��ID';
    lv_cnst_15        CONSTANT VARCHAR2(30)  := '���Y����LT';
    lv_type           CONSTANT VARCHAR2(30)  := '���l';
    cv_prod_class_1   CONSTANT VARCHAR2(1)   := '1'; -- 1�F���[�t
--
    -- *** ���[�J���ϐ� ***
--
    ln_tightening_program_id   NUMBER ; -- ���߃R���J�����gID
    ln_order_type_id           NUMBER ; -- �o�Ɍ`��ID
    ln_lead_time_day           NUMBER ; -- ���Y����LT
    lv_deliver_from           xxwsh_tightening_control.deliver_from%TYPE; -- �o�׌��ۊǏꏊ
    lv_sales_base             xxwsh_tightening_control.sales_branch%TYPE; -- ���_
    lv_sales_base_category    xxwsh_tightening_control.sales_branch_category%TYPE; -- ���_�J�e�S��
    ld_schedule_ship_date     xxwsh_tightening_control.schedule_ship_date%TYPE;    -- �o�ɓ�
    lv_base_record_class      xxwsh_tightening_control.base_record_class%TYPE;     -- ����R�[�h�敪
    lv_para                    VARCHAR2(30);
    lv_err_message             VARCHAR2(4000); -- �G���[���b�Z�[�W
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
    lv_para := lv_cnst_14;
    ln_order_type_id := TO_NUMBER(iv_order_type_id); -- �o�Ɍ`��ID
--
    lv_para := lv_cnst_15;
    ln_lead_time_day := TO_NUMBER(iv_lead_time_day); -- ���Y����LT
--
    lv_err_message := NULL;
--
    -- ==================================================
    -- �p�����[�^�`�F�b�N(H-1)
    -- ==================================================
--
    IF (iv_tighten_class IS NULL) THEN
      -- ���ߏ����敪��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_null,
                               'PARAMETER',
                               lv_cnst_06) || gv_line_feed;
    END IF;
--
    IF (iv_tighten_class = cv_tighten_class_1) THEN
      -- ���ߏ����敪��1:����̏ꍇ
      ln_tightening_program_id := NULL;
--
      IF (iv_prod_class = cv_prod_class_1) THEN
        -- �p�����[�^.���i�敪�����[�t�̏ꍇ
        IF (ln_order_type_id IS NULL) THEN
          -- �o�Ɍ`��ID��NULL�`�F�b�N���s���܂�
          lv_err_message := lv_err_message ||
          xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                   gv_cnst_msg_null,
                                   'PARAMETER',
                                   lv_cnst_01) || gv_line_feed;
        END IF;
--
      END IF;
--
      IF (ln_lead_time_day IS NULL) THEN
        -- ���Y����LT��NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_03) || gv_line_feed;
      END IF;
--
      IF (id_schedule_ship_date IS NULL) THEN
        -- �o�ɓ���NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_04) || gv_line_feed;
      END IF;
--
      IF (iv_base_record_class IS NULL) THEN
        -- ����R�[�h�敪��NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_05) || gv_line_feed;
      END IF;
--
      IF (iv_prod_class IS NULL) THEN
        -- ���i�敪��NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_08) || gv_line_feed;
      END IF;
--
      -- �u�o�ɓ��v�`���`�F�b�N
      IF (gn_status_error
          = xxcmn_common_pkg.check_param_date_yyyymmdd(id_schedule_ship_date)) THEN
        -- �o�ɓ���YYYY/MM/DD�łȂ��ꍇ�A�G���[��Ԃ�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_fomt,
                                 'PARAMETER',
                                 lv_cnst_04,
                                 'DATE',
                                 lv_cnst_10) || gv_line_feed;
      END IF;
--
--
    ELSIF (iv_tighten_class = cv_tighten_class_2) THEN
      -- ���ߏ����敪��2:�Ē��߂̏ꍇ
      lv_para := lv_cnst_13;
      ln_tightening_program_id := TO_NUMBER(iv_tightening_program_id);
--
      IF (iv_tighten_class IS NULL) THEN
        -- ���ߏ����敪��NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_06) || gv_line_feed;
      END IF;
--
      IF (ln_tightening_program_id IS NULL) THEN
        -- ���߃R���J�����gID��NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_07) || gv_line_feed;
      END IF;
--
      IF (iv_prod_class IS NULL) THEN
        -- ���i�敪��NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_08) || gv_line_feed;
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** ���b�Z�[�W�̐��`
    -- **************************************************
    -- ���b�Z�[�W���o�^����Ă���ꍇ
    IF (lv_err_message IS NOT NULL) THEN
      -- �Ō�̉��s�R�[�h���폜��OUT�p�����[�^�ɐݒ�
      lv_errmsg := RTRIM(lv_err_message, gv_line_feed);
      -- �G���[�Ƃ��ďI��
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- �p�����[�^�ݒ�(H-2)
    -- ==================================================
    -- ���ߏ����敪��1:������߂̏ꍇ
    IF (iv_tighten_class = cv_tighten_class_1) THEN
      lv_deliver_from        := iv_deliver_from;
      lv_sales_base          := iv_sales_base;
      lv_sales_base_category := iv_sales_base_category;
      ld_schedule_ship_date  := id_schedule_ship_date;
      lv_base_record_class   := iv_base_record_class;
    -- ���ߏ����敪��2:�Ē��߂̏ꍇ
    ELSIF (iv_tighten_class = cv_tighten_class_2) THEN
      -- ���ߊǗ��A�h�I�����擾
      SELECT
        DECODE(order_type_id,gn_all,NULL
                            ,order_type_id), -- �o�Ɍ`��ID
        DECODE(deliver_from,gv_all,NULL
                           ,deliver_from),  -- �o�Ɍ�
        DECODE(sales_branch,gv_all,NULL
                           ,sales_branch),  -- ���_
        DECODE(sales_branch_category,gv_all,NULL
                                    ,sales_branch_category), -- ���_�J�e�S��
        lead_time_day,               -- ���Y����LT
        schedule_ship_date           -- �o�ɓ�
      INTO
        ln_order_type_id,               -- �o�Ɍ`��ID
        lv_deliver_from,                -- �o�Ɍ�
        lv_sales_base,                  -- ���_
        lv_sales_base_category,         -- ���_�J�e�S��
        ln_lead_time_day,               -- ���Y����LT
        ld_schedule_ship_date           -- �o�ɓ�
      FROM
        xxwsh_tightening_control xtc
      WHERE 
        xtc.concurrent_id = ln_tightening_program_id
      ;
      lv_base_record_class   := 'N';   -- ����R�[�h�敪
    END IF;
    -- ==================================================
    -- �o�׈˗��m��֐��N��(H-3)
    -- ==================================================
    xxwsh400004c.ship_tightening(
      ln_order_type_id,               -- �o�Ɍ`��ID
      lv_deliver_from,                -- �o�׌�
      lv_sales_base,                  -- ���_
      lv_sales_base_category,         -- ���_�J�e�S��
      ln_lead_time_day,               -- ���Y����LT
      ld_schedule_ship_date,          -- �o�ɓ�
      lv_base_record_class,           -- ����R�[�h�敪
      iv_request_no,                  -- �˗�No
      iv_tighten_class,               -- ���ߏ����敪
      ln_tightening_program_id,       -- ���߃R���J�����gID
      cv_tightening_status_chk_cla_1, -- ���߃X�e�[�^�X�`�F�b�N�敪 1�F�`�F�b�N�L��
      cv_callfrom_flg_1,              -- �ďo���t���O 1�F�R���J�����g
      iv_prod_class,                  -- ���i�敪
      iv_instruction_dept,            -- ����
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_warn) THEN
      -- ���[�j���O�̏ꍇ
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_216,
                                            gv_tkn_api_name,
                                            lv_cnst_12,
                                            'ERR_MSG',
                                            lv_errmsg);
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
    ELSIF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_215,
                                            gv_tkn_api_name,
                                            lv_cnst_11,
                                            'ERR_MSG',
                                            lv_errmsg,
                                            'REQUEST_NO',
                                            iv_request_no);
--
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���l�ϊ��G���[�n���h�� ***
    WHEN INVALID_NUMBER THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_222,
                                              'PARAMETER',
                                              lv_para,
                                              'TYPE',
                                              lv_type);
      RAISE global_process_expt;
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
    errbuf                   OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT NOCOPY VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_order_type_id         IN  VARCHAR2,                -- �o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2,                -- �o�׌�
    iv_sales_base            IN  VARCHAR2,                -- ���_
    iv_sales_base_category   IN  VARCHAR2,                -- ���_�J�e�S��
    iv_lead_time_day         IN  VARCHAR2,                -- ���Y����LT
    iv_schedule_ship_date    IN  VARCHAR2,                -- �o�ɓ�
    iv_base_record_class     IN  VARCHAR2,                -- ����R�[�h�敪
    iv_request_no            IN  VARCHAR2,                -- �˗�No
    iv_tighten_class         IN  VARCHAR2,                -- ���ߏ����敪
    iv_prod_class            IN  VARCHAR2,                -- ���i�敪
    iv_tightening_program_id IN  VARCHAR2,                -- ���߃R���J�����gID
    iv_instruction_dept      IN  VARCHAR2                 -- ����
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
      iv_order_type_id,                            -- �o�Ɍ`��ID
      iv_deliver_from,                             -- �o�׌�
      iv_sales_base,                               -- ���_
      iv_sales_base_category,                      -- ���_�J�e�S��
      iv_lead_time_day,                            -- ���Y����LT
      FND_DATE.STRING_TO_DATE(iv_schedule_ship_date, 'YYYY/MM/DD'),-- �o�ɓ�
      iv_base_record_class,                        -- ����R�[�h�敪
      iv_request_no,                               -- �˗�No
      iv_tighten_class,                            -- ���ߏ����敪
      iv_prod_class,                               -- ���i�敪
      iv_tightening_program_id,                    -- ���߃R���J�����gID
      iv_instruction_dept,                         -- ����
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ======================
    -- ���[�j���O�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
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
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
END xxwsh400007c;
/
