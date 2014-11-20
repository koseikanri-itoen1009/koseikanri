CREATE OR REPLACE PACKAGE BODY xxwsh920002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920002C(body)
 * Description      : ������������
 * MD.050/070       : ���Y��������(�o�ץ�ړ�������)(T_MD050_BPO_920)
 *                    ������������                 (T_MD070_BPO_92D)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  pro_param_chk          ���̓p�����[�^�`�F�b�N           (G-1)
 *  pro_get_h_o_all        �o�׈˗��Ώۃf�[�^���o           (G-2)
 *  pro_get_mov_req        �ړ��w���Ώۃf�[�^���o           (G-3)
 *  pro_del_mov_lot        �ړ����b�h�ڍ�(�A�h�I��)�폜     (G-4)
 *  pro_upd_o_lines        �󒍖��׃A�h�I���X�V             (G-5)
 *  pro_upd_m_r_lines      �ړ��˗�/�w������(�A�h�I��)�X�V  (G-6)
 *  pro_out_msg            ���b�Z�[�W�o��                   (G-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/18    1.0   Tatsuya Kurata    �V�K�쐬
 *  2008/06/03    1.1   Masao Hokkanji    �����e�X�g�s��Ή�
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
--
--################################  �Œ蕔 END   ###############################
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���͂o�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
      item_class   VARCHAR2(2)   -- ���i�敪
     ,action_type  VARCHAR2(5)   -- �������
     ,block1       VARCHAR2(5)   -- �u���b�N�P
     ,block2       VARCHAR2(5)   -- �u���b�N�Q
     ,block3       VARCHAR2(5)   -- �u���b�N�R
     ,del_from_id  VARCHAR2(40)  -- �o�Ɍ�
     ,del_type     VARCHAR2(10)  -- �o�Ɍ`��
     ,del_d_from   VARCHAR2(10)  -- �o�ɓ�From
     ,del_d_to     VARCHAR2(10)  -- �o�ɓ�To
    );
--
  -- �o�׈˗��Ώۃf�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_order_line IS RECORD
    (
      o_line_id   xxwsh_order_lines_all.order_line_id%TYPE  -- �󒍖��׃A�h�I��ID
    );
  TYPE tab_data_order_line IS TABLE OF rec_order_line INDEX BY PLS_INTEGER;
--
  -- �ړ��w���Ώۃf�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_mov_line IS RECORD
    (
      m_line_id   xxinv_mov_req_instr_lines.mov_line_id%TYPE  -- �ړ�����ID
    );
  TYPE tab_data_mov_line IS TABLE OF rec_mov_line INDEX BY PLS_INTEGER;
--
  -- �󒍖��׃A�h�I���o�^�p���ڃe�[�u���^
  TYPE l_order_line_id     IS TABLE OF
       xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;    -- �󒍖��׃A�h�I��ID
--
  -- �ړ����׃A�h�I���o�^�p���ڃe�[�u���^
  TYPE mod_line_id         IS TABLE OF
       xxinv_mov_req_instr_lines.mov_line_id%TYPE INDEX BY BINARY_INTEGER;  -- �ړ�����ID
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;
  gn_normal_cnt    NUMBER;
  gn_error_cnt     NUMBER;
--
--################################  �Œ蕔 END   ###############################
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���萔
  -- ==================================================
  gv_pkg_name       CONSTANT VARCHAR2(15) := 'xxwsh920002c';          -- �p�b�P�[�W��
  -- �G���[���b�Z�[�W�R�[�h
  gv_application    CONSTANT VARCHAR2(5)  := 'XXWSH';                 -- �A�v���P�[�V����
  gv_err_del_count  CONSTANT VARCHAR2(20) := 'APP-XXWSH-02951';
                                                     -- �폜�������b�Z�[�W
  gv_err_para       CONSTANT VARCHAR2(20) := 'APP-XXWSH-12951';
                                                     -- �K�{���̓p�����[�^�����̓G���[���b�Z�[�W
  gv_err_format     CONSTANT VARCHAR2(20) := 'APP-XXWSH-12952';
                                                     -- ���̓p�����[�^�����G���[���b�Z�[�W
  gv_err_day_out    CONSTANT VARCHAR2(20) := 'APP-XXWSH-12953';
                                                     -- �Ώۊ��ԋt�]�G���[���b�Z�[�W
  gv_err_lock       CONSTANT VARCHAR2(20) := 'APP-XXWSH-12954';
                                                     -- ���b�N�G���[���b�Z�[�W
  -- �g�[�N��
  gv_tkn_count      CONSTANT VARCHAR2(5)  := 'COUNT';
  gv_tkn_prof_name  CONSTANT VARCHAR2(9)  := 'PROF_NAME';
  gv_tkn_parm_name  CONSTANT VARCHAR2(9)  := 'PARM_NAME';
  gv_tkn_table      CONSTANT VARCHAR2(5)  := 'TABLE';
  -- �G���[���X�g�\�����e
  gv_msg_skbn       CONSTANT VARCHAR2(8)  := '���i�敪';
  gv_msg_from       CONSTANT VARCHAR2(10) := '�o�ɓ�From';
  gv_msg_to         CONSTANT VARCHAR2(8)  := '�o�ɓ�To';
  gv_msg_lock_1     CONSTANT VARCHAR2(70) :=
                              '�󒍃w�b�_�A�h�I���A�󒍖��׃A�h�I���A�ړ����b�g�ڍ�(�A�h�I��)';
  gv_msg_lock_2     CONSTANT VARCHAR2(90) :=
        '�ړ��˗�/�w���w�b�_(�A�h�I��)�A�ړ��˗�/�w������(�A�h�I��)�A�ړ����b�g�ڍ�(�A�h�I��)';
--
  gv_yes            CONSTANT VARCHAR2(1)  := 'Y';
  gv_s_req          CONSTANT VARCHAR2(1)  := '1';   -- ������ʁu�o�׈˗��v
  gv_m_req          CONSTANT VARCHAR2(1)  := '3';   -- ������ʁu�ړ��w���˗��v
  gv_lot            CONSTANT VARCHAR2(1)  := '1';   -- ���b�g�u���b�g�Ǘ��i�v
  gv_product        CONSTANT VARCHAR2(1)  := '5';   -- �i�ڋ敪�u���i�v
  gv_kbn_ship       CONSTANT VARCHAR2(1)  := '1';   -- �o�׎x���敪�u�o�׈˗��v
  gv_mov_y          CONSTANT VARCHAR2(1)  := '1';   -- �ړ��^�C�v�u�ϑ�����v
  gv_out            CONSTANT VARCHAR2(2)  := '03';  -- �X�e�[�^�X�u���ߍρv
  gv_req            CONSTANT VARCHAR2(2)  := '02';  -- �X�e�[�^�X�u�˗��ρv
  gv_adjust         CONSTANT VARCHAR2(2)  := '03';  -- �X�e�[�^�X�u�������v
  gv_n_notif        CONSTANT VARCHAR2(2)  := '10';  -- �ʒm�X�e�[�^�X�u���ʒm�v
  gv_re_notif       CONSTANT VARCHAR2(2)  := '20';  -- �ʒm�X�e�[�^�X�u�Ēʒm�v�v
  gv_ship_req       CONSTANT VARCHAR2(2)  := '10';  -- �����^�C�v�u�o�׈˗��v
  gv_move_req       CONSTANT VARCHAR2(2)  := '20';  -- �����^�C�v�u�ړ��w���v
  gv_auto           CONSTANT VARCHAR2(2)  := '10';  -- �����蓮�����敪�u���������v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate           DATE;                -- �V�X�e�����ݓ��t
  gd_del_from          DATE;                -- �o�ɓ�From(Date�֕ϊ��p)
  gd_del_to            DATE;                -- �o�ɓ�To  (Date�֕ϊ��p)
--
  -- �v�g�n�J�����擾�p
  gn_last_upd_by       NUMBER;              -- �ŏI�X�V��
  gd_last_upd_date     DATE;                -- �ŏI�X�V��
  gn_last_upd_login    NUMBER;              -- �ŏI�X�V���O�C��
  gn_request_id        NUMBER;              -- �v��ID
  gn_prog_appl_id      NUMBER;              -- �v���O�����A�v���P�[�V����ID
  gn_prog_id           NUMBER;              -- �v���O����ID
--
  gn_del_cut           NUMBER DEFAULT 0;    -- �폜�����p
  gn_l_id_cnt          NUMBER DEFAULT 0;    -- �o�׈˗��Ώۃ��R�[�h�p�J�E���g
  gn_m_id_cnt          NUMBER DEFAULT 0;    -- �ړ��w���Ώۃ��R�[�h�p�J�E���g
--
  -- �r�p�k�쐬�p
  gv_sql_sel           VARCHAR2(20000);     -- SQL�g�����p
  gv_sql_select        VARCHAR2(1000);      -- SELECT��
  gv_sql_from          VARCHAR2(3000);      -- FROM��
  gv_sql_where         VARCHAR2(9000);      -- WHERE��
  gv_sql_in_para_1     VARCHAR2(1000);      -- ���͂o�C�ӕ���1(�u���b�N�P�`�R�̂ݓ��͗L)
  gv_sql_in_para_2     VARCHAR2(1000);      -- ���͂o�C�ӕ���2(�o�Ɍ��̂ݓ��͗L)
  gv_sql_in_para_3     VARCHAR2(1000);      -- ���͂o�C�ӕ���3(�u���b�N�P�`�R�A�o�Ɍ����͗L)
  gv_sql_in_para_4     VARCHAR2(1000);      -- ���͂o�C�ӕ���4(�o�Ɍ`�� ���͗L)
--
  gr_param             rec_param_data;      -- ���̓p�����[�^
  gt_order_line        tab_data_order_line; -- �o�׈˗��Ώێ擾�f�[�^
  gt_mov_line          tab_data_mov_line;   -- �ړ��w���Ώێ擾�f�[�^
  gt_l_order_line_id   l_order_line_id;     -- �󒍖��׃A�h�I��ID
  gt_mod_line_id       mod_line_id;         -- �ړ�����ID
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_error_expt          EXCEPTION;     -- ���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : pro_param_chk
   * Description      : ���̓p�����[�^�`�F�b�N   (G-1)
   ***********************************************************************************/
  PROCEDURE pro_param_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_param_chk'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
    -- ���̓p�����[�^�K�{�`�F�b�N
    ------------------------------------------
    -- ���͂o�u���i�敪�v�̕K�{�`�F�b�N
    IF (gr_param.item_class IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_para          -- �K�{���͂o���ݒ�G���[
                                    ,gv_tkn_parm_name     -- �g�[�N��
                                    ,gv_msg_skbn          -- �u���i�敪�v
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���͂o�u�o�ɗ\���From�v�̕K�{�`�F�b�N
    IF (gr_param.del_d_from IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_para          -- �K�{���͂o���ݒ�G���[
                                    ,gv_tkn_parm_name     -- �g�[�N��
                                    ,gv_msg_from          -- �u�o�ɓ�From�v
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���͂o�u�o�ɗ\���To�v�̕K�{�`�F�b�N
    IF (gr_param.del_d_to IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_para          -- �K�{���͂o���ݒ�G���[
                                    ,gv_tkn_parm_name     -- �g�[�N��
                                    ,gv_msg_to            -- �u�o�ɓ�To�v
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- ���t�`�F�b�N
    ------------------------------------------
    -- ���͂o�u�o�ɗ\���From�v�̏����ϊ�(YYYY/MM/DD)
    gd_del_from := FND_DATE.STRING_TO_DATE(gr_param.del_d_from,'YYYY/MM/DD');
    -- �ϊ��G���[��
    IF (gd_del_from IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_format        -- ���͂o�����G���[
                                    ,gv_tkn_parm_name     -- �g�[�N��
                                    ,gv_msg_from          -- �u�o�ɓ�From�v
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���͂o�u�o�ɗ\���To�v�̏����ϊ�(YYYY/MM/DD)
    gd_del_to := FND_DATE.STRING_TO_DATE(gr_param.del_d_to,'YYYY/MM/DD');
    -- �ϊ��G���[��
    IF (gd_del_to IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application     -- 'XXWSH'
                                    ,gv_err_format      -- ���͂o�����G���[
                                    ,gv_tkn_parm_name   -- �g�[�N��
                                    ,gv_msg_to          -- �u�o�ɓ�To�v
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- �Ó����`�F�b�N
    ------------------------------------------
    -- �o�ɗ\���From���o�ɗ\���To���傫���ꍇ�A�G���[
    IF (gd_del_from > gd_del_to) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                                                     gv_application    -- 'XXWSH'
                                                    ,gv_err_day_out    -- �Ώۊ��ԋt�]�G���[
                                                   )
                                                   ,1
                                                   ,5000);
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
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_param_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_h_o_all
   * Description      : �o�׈˗��Ώۃf�[�^���o  (G-2)
   ***********************************************************************************/
  PROCEDURE pro_get_h_o_all
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_h_o_all'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���b�N�p�J�[�\��
    CURSOR cur_get_lock
    IS
      SELECT xoha.order_header_id
      FROM  xxwsh_order_headers_all       xoha    -- �󒍃w�b�_�A�h�I��
           ,xxwsh_order_lines_all         xola    -- �󒍖��׃A�h�I��
           ,xxinv_mov_lot_details         xmld    -- �ړ����b�g�ڍׁi�A�h�I���j
      WHERE xoha.order_header_id           = xola.order_header_id  -- �󒍃w�b�_�A�h�I��ID
      AND   xoha.latest_external_flag      = gv_yes                -- �ŐV�t���O�u�x�v
      AND   xoha.req_status                = gv_out                -- �X�e�[�^�X�u���ߍρv
      AND ( xoha.notif_status              = gv_n_notif            -- �ʒm�X�e�[�^�X�u���ʒm�v
         OR xoha.notif_status              = gv_re_notif)          -- �ʒm�X�e�[�^�X�u�Ēʒm�v�v
      AND   xola.delete_flag              <> gv_yes                -- �폜�t���O�u�x�v�ȊO
      AND   xola.automanual_reserve_class  = gv_auto               -- �����蓮�����敪�u���������v
      AND   xola.order_line_id             = xmld.mov_line_id      -- ����ID
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�N�p�J�[�\���I�[�v��
    OPEN cur_get_lock;
    -- ���b�N�p�J�[�\���N���[�Y
    CLOSE cur_get_lock;
--
    ---------------------------------------------------------
    -- ���ISQL�쐬
    ---------------------------------------------------------
    -- SELECT��
    gv_sql_select := 'SELECT xola.order_line_id          AS o_line_id';  -- �󒍖��׃A�h�I��ID
--
    -- FROM��
    gv_sql_from := ' FROM xxwsh_order_headers_all       xoha    -- �󒍃w�b�_�A�h�I��
                        ,xxwsh_order_lines_all         xola    -- �󒍖��׃A�h�I��
                        ,xxinv_mov_lot_details         xmld    -- �ړ����b�g�ڍׁi�A�h�I���j
                        ,xxwsh_oe_transaction_types_v  xottv   -- �󒍃^�C�v���VIEW
                        ,xxcmn_item_locations_v        xilv    -- OPM�ۊǏꏊ���VIEW
                        ,xxcmn_item_mst_v              ximv    -- OPM�i�ڏ��VIEW
                        ,xxcmn_item_categories4_v      xicv    -- OPM�i�ڃJ�e�S���������VIEW4
                   ';
--
    -- WHERE��
    gv_sql_where :=
      ' WHERE xoha.schedule_ship_date      >= :para_del_from            -- ���͂o�u�o�ɗ\���From�v
        AND   xoha.schedule_ship_date      <= :para_del_to              -- ���͂o�u�o�ɗ\���To�v
        AND   xoha.deliver_from             = xilv.segment1             -- �ۊǑq�ɃR�[�h
        AND   ximv.item_no                  = xola.shipping_item_code   -- �o�וi��
        AND   ximv.lot_ctl                  = :para_lot                 -- ���b�g�i���b�g�Ǘ��i�j
        AND   xicv.item_class_code          = :para_product             -- �i�ڋ敪�i���i�j
        AND   xicv.item_id                  = ximv.item_id              -- �i��ID
        AND   xicv.prod_class_code          = :para_item_class          -- ���͂o�u���i�敪�v
        AND   xoha.req_status               = :para_out                 -- �X�e�[�^�X�u���ߍρv
        AND  (xoha.notif_status             = :para_n_notif             -- �ʒm�X�e�[�^�X�u���ʒm�v
          OR  xoha.notif_status             = :para_re_notif)           -- �ʒm�X�e�[�^�X�u�Ēʒm�v�v
        AND   xoha.latest_external_flag     = :para_new                 -- �ŐV�t���O�u�x�v
        AND   xoha.order_type_id            = xottv.transaction_type_id -- �󒍃^�C�vID
        AND   xottv.shipping_shikyu_class   = :para_kbn_ship            -- �o�׎x���敪�u�o�׈˗��v
        AND   xoha.order_header_id          = xola.order_header_id      -- �󒍃w�b�_�A�h�I��ID
        AND   xola.delete_flag             <> :para_delete              -- �폜�t���O�u�x�v�ȊO
        AND   xola.automanual_reserve_class = :para_auto                -- �����蓮�����敪�u���������v
        AND   xola.order_line_id            = xmld.mov_line_id          -- ����ID
        AND   xola.shipped_quantity         IS NULL                     -- �o�׎��ѐ���(NULL�̂ݑΏ�)
      ';
--
    -- ���͂o�C�ӕ���1�i���͂o�u�u���b�N�v�̂��������ꂩ�ɓ��͂�����ꍇ�j
    gv_sql_in_para_1 := ' AND (xilv.distribution_block  = :para_block1  -- �����u���b�N
                            OR xilv.distribution_block  = :para_block2  -- �����u���b�N
                            OR xilv.distribution_block  = :para_block3) -- �����u���b�N
                        ';
--
    -- ���͂o�C�ӕ���2�i���͂o�u�o�Ɍ��v�ɓ��͂�����̏ꍇ)
    gv_sql_in_para_2 := ' AND xoha.deliver_from         = :para_del_from_id';  -- �o�׌�
--
    -- ���͂o�C�ӕ���3�i���͂o�u�u���b�N�v�̂��������ꂩ�ɓ��͂�����A�o�Ɍ������͂���̏ꍇ�j
    gv_sql_in_para_3 := ' AND ((xilv.distribution_block = :para_block1       -- �����u���b�N
                            OR xilv.distribution_block  = :para_block2       -- �����u���b�N
                            OR xilv.distribution_block  = :para_block3)      -- �����u���b�N
                          OR   xoha.deliver_from        = :para_del_from_id) -- �o�׌�
                        ';
    -- ���͂o�C�ӕ���4�i�o�Ɍ`�� ���͗L�j
    gv_sql_in_para_4 := ' AND xoha.order_type_id            = :para_del_type';   -- ���͂o�u�o�Ɍ`�ԁv
--
    -------------------------------------------------------------
    -- �f�[�^���o�pSQL�쐬
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE�匋��
--
    -- �C�ӓ��͂o�̓��͑��݃`�F�b�N�����A���݂��Ă���ꍇ�́A������ǉ�
    IF ((gr_param.block1 IS NOT NULL)
    OR  (gr_param.block2 IS NOT NULL)
    OR  (gr_param.block3 IS NOT NULL))
    THEN
      -- �u���b�N�̂����ꂩ�ɓ��͂�����A�o�Ɍ��ɂ����͂�����ꍇ
      IF (gr_param.del_from_id IS NOT NULL) THEN
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_3;  -- ���͂o�C�ӕ���3����
      -- �u���b�N�̂����ꂩ�ɓ��͂����邪�A�o�Ɍ���NULL�̏ꍇ
      ELSE
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_1;  -- ���͂o�C�ӕ���1����
      END IF;
    -- �u���b�N�S�Ă��m�t�k�k�ŁA�o�Ɍ��ɓ��͂�����ꍇ
    ELSIF (gr_param.del_from_id IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_2;  -- ���͂o�C�ӕ���2����
    END IF;
--
    -- ���͂o�u�o�Ɍ`�ԁv�̓��̓`�F�b�N
    IF (gr_param.del_type IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_4;  -- ���͂o�C�ӕ���4����
    END IF;
--
    ---------------------------------
    -- �쐬SQL�����s
    ---------------------------------
    -- �C�ӓ��͂o�̓��͑��݃`�F�b�N
    IF (gr_param.del_type IS NOT NULL) THEN
      -- ���͂o�u�o�Ɍ`�ԁv�ɓ��͂�����ꍇ
      IF ((gr_param.block1 IS NOT NULL)
      OR  (gr_param.block2 IS NOT NULL)
      OR  (gr_param.block3 IS NOT NULL))
      THEN
        -- �u���b�N�̂����ꂩ�ɓ��͂�����A�o�Ɍ��ɂ����͂�����ꍇ
        IF (gr_param.del_from_id IS NOT NULL) THEN
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ,gr_param.del_from_id
                                                                            ,gr_param.del_type
                                                                            ;
        -- �u���b�N�̂����ꂩ�ɓ��͂����邪�A�o�Ɍ���NULL�̏ꍇ
        ELSE
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ,gr_param.del_type
                                                                            ;
        END IF;
      -- �u���b�N�S�Ă�NULL�ŁA�o�Ɍ��ɓ��͂�����ꍇ
      ELSIF (gr_param.del_from_id IS NOT NULL) THEN
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ,gr_param.del_from_id
                                                                          ,gr_param.del_type
                                                                          ;
      -- �C�ӓ��͂o�S��NULL�̏ꍇ
      ELSE
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ,gr_param.del_type
                                                                          ;
      END IF;
    ELSE
      -- ���͂o�u�o�Ɍ`�ԁv��NULL�̏ꍇ
      IF ((gr_param.block1 IS NOT NULL)
      OR  (gr_param.block2 IS NOT NULL)
      OR  (gr_param.block3 IS NOT NULL))
      THEN
        -- �u���b�N�̂����ꂩ�ɓ��͂�����A�o�Ɍ��ɂ����͂�����ꍇ
        IF (gr_param.del_from_id IS NOT NULL) THEN
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ,gr_param.del_from_id
                                                                            ;
        -- �u���b�N�̂����ꂩ�ɓ��͂����邪�A�o�Ɍ���NULL�̏ꍇ
        ELSE
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ;
        END IF;
      -- �u���b�N�S�Ă�NULL�ŁA�o�Ɍ��ɓ��͂�����ꍇ
      ELSIF (gr_param.del_from_id IS NOT NULL) THEN
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ,gr_param.del_from_id
                                                                          ;
      -- �C�ӓ��͂o�S��NULL�̏ꍇ
      ELSE
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN lock_error_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_lock%ISOPEN) THEN
        CLOSE cur_get_lock;
      END IF;
--
      ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXWSH'
                                                     ,gv_err_lock      -- ���b�N�G���[
                                                     ,gv_tkn_table     -- �g�[�N��
                                                     ,gv_msg_lock_1    -- �e�[�u����
                                                    )
                                                    ,1
                                                    ,5000);
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� **
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_h_o_all;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_mov_req
   * Description      : �ړ��w���Ώۃf�[�^���o  (G-3)
   ***********************************************************************************/
  PROCEDURE pro_get_mov_req
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_mov_req'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���b�N�p�J�[�\��
    CURSOR cur_get_lock
    IS
      SELECT xmrih.mov_hdr_id
      FROM xxinv_mov_req_instr_headers   xmrih   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          ,xxinv_mov_req_instr_lines     xmril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
          ,xxinv_mov_lot_details         xmld    -- �ړ����b�g�ڍׁi�A�h�I���j
      WHERE xmrih.mov_type                 = gv_mov_y               -- �ړ��^�C�v�u�ϑ�����v
      AND   xmrih.mov_hdr_id               = xmril.mov_hdr_id       -- �ړ��w�b�_ID
      AND ( xmrih.status                   = gv_req                 -- �X�e�[�^�X�u�˗��ρv
         OR xmrih.status                   = gv_adjust)             -- �X�e�[�^�X�u�������v
      AND ( xmrih.notif_status             = gv_n_notif             -- �ʒm�X�e�[�^�X�u���ʒm�v
         OR xmrih.notif_status             = gv_re_notif)           -- �ʒm�X�e�[�^�X�u�Ēʒm�v�v
      AND   xmril.delete_flg              <> gv_yes                 -- �폜�t���O�u�x�v�ȊO
      AND   xmril.automanual_reserve_class = gv_auto                -- �����蓮�����敪�u���������v
      AND   xmril.mov_line_id              = xmld.mov_line_id       -- �ړ�����ID
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�N�p�J�[�\���I�[�v��
    OPEN cur_get_lock;
    -- ���b�N�p�J�[�\���N���[�Y
    CLOSE cur_get_lock;
--
    ---------------------------------------------------------
    -- ���ISQL�쐬
    ---------------------------------------------------------
    -- SELECT��
    gv_sql_select := 'SELECT xmril.mov_line_id  AS m_line_id';    -- �ړ�����ID
--
    -- FROM��
    gv_sql_from := ' FROM xxinv_mov_req_instr_headers   xmrih  -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
                         ,xxinv_mov_req_instr_lines     xmril  -- �ړ��˗�/�w�����ׁi�A�h�I���j
                         ,xxinv_mov_lot_details         xmld   -- �ړ����b�g�ڍׁi�A�h�I���j
                         ,xxcmn_item_locations_v        xilv   -- OPM�ۊǏꏊ���VIEW
                         ,xxcmn_item_mst_v              ximv   -- OPM�i�ڏ��VIEW
                         ,xxcmn_item_categories4_v      xicv   -- OPM�i�ڃJ�e�S���������VIEW4
                   ';
--
    -- WHERE��
    gv_sql_where :=
      ' WHERE xmrih.schedule_ship_date      >= :para_del_from      -- ���͂o�u�o�ɗ\���From�v
        AND   xmrih.schedule_ship_date      <= :para_del_to        -- ���͂o�u�o�ɗ\���To�v
        AND   xmrih.shipped_locat_code       = xilv.segment1       -- �ۊǑq�ɃR�[�h
        AND   xmrih.mov_type                 = :para_mov_y         -- �ړ��^�C�v�u�ϑ�����v
        AND   ximv.item_no                   = xmril.item_code     -- �i��
        AND   ximv.lot_ctl                   = :para_lot           -- ���b�g�i���b�g�Ǘ��i�j
        AND   xicv.item_class_code           = :para_product       -- �i�ڋ敪�i���i�j
        AND   xicv.item_id                   = ximv.item_id        -- �i��ID
        AND    xicv.prod_class_code          = :para_item_class    -- ���͂o�u���i�敪�v
        AND ( xmrih.status                   = :para_req           -- �X�e�[�^�X�u�˗��ρv
          OR  xmrih.status                   = :para_adjust)       -- �X�e�[�^�X�u�������v
        AND ( xmrih.notif_status             = :para_n_notif       -- �ʒm�X�e�[�^�X�u���ʒm�v
          OR  xmrih.notif_status             = :para_re_notif)     -- �ʒm�X�e�[�^�X�u�Ēʒm�v�v
        AND   xmrih.mov_hdr_id               = xmril.mov_hdr_id    -- �ړ��w�b�_ID
        AND   xmril.delete_flg              <> :para_delete        -- �폜�t���O�u�x�v�ȊO
        AND   xmril.automanual_reserve_class = :para_auto          -- �����蓮�����敪�u���������v
        AND   xmril.mov_line_id              = xmld.mov_line_id    -- �ړ�����ID
        AND   xmril.shipped_quantity         IS NULL               -- �o�Ɏ��ѐ���(NULL�̂ݑΏ�)
        AND   xmril.ship_to_quantity         IS NULL               -- ���Ɏ��ѐ���(NULL�̂ݑΏ�)
      ';
--
    -- ���͂o�C�ӕ���1�i���͂o�u�u���b�N�v�̂��������ꂩ�ɓ��͂�����ꍇ�j
    gv_sql_in_para_1 := ' AND (xilv.distribution_block  = :para_block1  -- �����u���b�N
                            OR xilv.distribution_block  = :para_block2  -- �����u���b�N
                            OR xilv.distribution_block  = :para_block3) -- �����u���b�N
                        ';
--
    -- ���͂o�C�ӕ���2�i���͂o�u�o�Ɍ��v�ɓ��͂�����̏ꍇ�j
-- 2008/06/03 START
--    gv_sql_in_para_2 := ' AND xoha.deliver_from         = :para_del_from_id';  -- �o�׌�
    gv_sql_in_para_2 := ' AND xmrih.shipped_locat_code = :para_del_from_id';  -- �o�׌�
-- 2008/06/03  END
--
    -- ���͂o�C�ӕ���3�i���͂o�u�u���b�N�v�̂��������ꂩ�ɓ��͂�����A�o�Ɍ������͂���̏ꍇ�j
    gv_sql_in_para_3 := ' AND ((xilv.distribution_block = :para_block1       -- �����u���b�N
                            OR xilv.distribution_block  = :para_block2       -- �����u���b�N
                            OR xilv.distribution_block  = :para_block3)      -- �����u���b�N
                          OR   xmrih.shipped_locat_code = :para_del_from_id) -- �o�Ɍ��ۊǏꏊ
                        ';
--
    -------------------------------------------------------------
    -- �f�[�^���o�pSQL�쐬
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE�匋��
--
    -- �C�ӓ��͂o�̓��͑��݃`�F�b�N��������݂��Ă���ꍇ�ͤ������ǉ�
    IF ((gr_param.block1 IS NOT NULL)
    OR  (gr_param.block2 IS NOT NULL)
    OR  (gr_param.block3 IS NOT NULL))
    THEN
      -- �u���b�N�̂����ꂩ�ɓ��͂����褏o�Ɍ��ɂ����͂�����ꍇ
      IF (gr_param.del_from_id IS NOT NULL) THEN
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_3;  -- ���͂o�C�ӕ���3����
      -- �u���b�N�̂����ꂩ�ɓ��͂����邪��o�Ɍ���NULL�̏ꍇ
      ELSE
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_1;  -- ���͂o�C�ӕ���1����
      END IF;
    -- �u���b�N�S�Ă�NULL�Ť�o�Ɍ��ɓ��͂�����ꍇ
    ELSIF (gr_param.del_from_id IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_2;  -- ���͂o�C�ӕ���2����
    END IF;
--
    ---------------------------------
    -- �쐬SQL�����s
    ---------------------------------
    -- ���͂o�u�o�Ɍ`�ԁv��NULL�̏ꍇ
    IF ((gr_param.block1 IS NOT NULL)
    OR  (gr_param.block2 IS NOT NULL)
    OR  (gr_param.block3 IS NOT NULL))
    THEN
      -- �u���b�N�̂����ꂩ�ɓ��͂����褏o�Ɍ��ɂ����͂�����ꍇ
      IF (gr_param.del_from_id IS NOT NULL) THEN
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                        ,gd_del_to
                                                                        ,gv_mov_y
                                                                        ,gv_lot
                                                                        ,gv_product
                                                                        ,gr_param.item_class
                                                                        ,gv_req
                                                                        ,gv_adjust
                                                                        ,gv_n_notif
                                                                        ,gv_re_notif
                                                                        ,gv_yes
                                                                        ,gv_auto
                                                                        ,gr_param.block1
                                                                        ,gr_param.block2
                                                                        ,gr_param.block3
                                                                        ,gr_param.del_from_id
                                                                        ;
      -- �u���b�N�̂����ꂩ�ɓ��͂����邪��o�Ɍ���NULL�̏ꍇ
      ELSE
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                        ,gd_del_to
                                                                        ,gv_mov_y
                                                                        ,gv_lot
                                                                        ,gv_product
                                                                        ,gr_param.item_class
                                                                        ,gv_req
                                                                        ,gv_adjust
                                                                        ,gv_n_notif
                                                                        ,gv_re_notif
                                                                        ,gv_yes
                                                                        ,gv_auto
                                                                        ,gr_param.block1
                                                                        ,gr_param.block2
                                                                        ,gr_param.block3
                                                                        ;
      END IF;
    -- �u���b�N�S�Ă�NULL�Ť�o�Ɍ��ɓ��͂�����ꍇ
    ELSIF (gr_param.del_from_id IS NOT NULL) THEN
      EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                      ,gd_del_to
                                                                      ,gv_mov_y
                                                                      ,gv_lot
                                                                      ,gv_product
                                                                      ,gr_param.item_class
                                                                      ,gv_req
                                                                      ,gv_adjust
                                                                      ,gv_n_notif
                                                                      ,gv_re_notif
                                                                      ,gv_yes
                                                                      ,gv_auto
                                                                      ,gr_param.del_from_id
                                                                      ;
    -- �C�ӓ��͂o�S��NULL�̏ꍇ
    ELSE
      EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                      ,gd_del_to
                                                                      ,gv_mov_y
                                                                      ,gv_lot
                                                                      ,gv_product
                                                                      ,gr_param.item_class
                                                                      ,gv_req
                                                                      ,gv_adjust
                                                                      ,gv_n_notif
                                                                      ,gv_re_notif
                                                                      ,gv_yes
                                                                      ,gv_auto
                                                                      ;
    END IF;
--
  EXCEPTION
    WHEN lock_error_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_lock%ISOPEN) THEN
        CLOSE cur_get_lock;
      END IF;
--
      ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXWSH'
                                                     ,gv_err_lock      -- ���b�N�G���[
                                                     ,gv_tkn_table     -- �g�[�N��
                                                     ,gv_msg_lock_2    -- �e�[�u����
                                                    )
                                                    ,1
                                                    ,5000);
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_mov_req;
--
  /**********************************************************************************
   * Procedure Name   : pro_del_mov_lot
   * Description      : �ړ����b�h�ڍׁi�A�h�I���j�폜  (G-4)
   ***********************************************************************************/
  PROCEDURE pro_del_mov_lot
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_del_mov_lot'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_cnt  NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���͂o�u������ʁv���w�o�׈˗��x���w�w��Ȃ�(ALL)�x�̏ꍇ����s
    IF ((gr_param.action_type = gv_s_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- �󒍖��׃A�h�I��ID�i�[
      <<o_line_id_data_loop>>
      FOR i IN 1..gt_order_line.COUNT LOOP
        -- LOOP�J�E���g�p�ϐ��փJ�E���g���}��
        gn_l_id_cnt := i;
--
        gt_l_order_line_id(gn_l_id_cnt) := gt_order_line(i). o_line_id;  -- �󒍖��׃A�h�I��ID
      END LOOP o_line_id_data_loop;
--
      -- �o�׈˗��Ώۃf�[�^���o�Ŏ擾�����󒍖��׃A�h�I��ID�ɑΉ������ړ����b�h�ڍׂ��ꊇ�폜
      FORALL o_id_cnt IN 1 .. gt_l_order_line_id.COUNT
        DELETE
        FROM xxinv_mov_lot_details  xmld    -- �ړ����b�g�ڍׁi�A�h�I���j
        WHERE xmld.mov_line_id        = gt_l_order_line_id(o_id_cnt)  -- �󒍖��׃A�h�I��ID
        AND   xmld.document_type_code = gv_ship_req                   -- �����^�C�v�u�o�׈˗��v
        ;
--
      -- �폜�������J�E���g
-- 2008/06/03 START �J�[�\���ŏ�������Ȃ��ꍇSQL%rowcount�͑O��SQL�̏���������
-- �\�����邽�ߏ�L�J�[�\�������s���ꂽ�ꍇ�̂ݎ��s����悤�ɏ�����ǉ�
      -- �Ώۂ̎󒍖��׃A�h�I��ID���ꌏ�ȏ�̏ꍇ�폜���������Z
      IF (gt_order_line.COUNT >= 1) THEN
        ln_cnt := SQL%rowcount;
        gn_del_cut := gn_del_cut + ln_cnt;
      END IF;
-- 2008/06/03 END
--
    END IF;
--
    -- ���͂o�u������ʁv���w�ړ��w���˗��x���w�w��Ȃ�(ALL)�x�̏ꍇ����s
    IF ((gr_param.action_type = gv_m_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- �ړ�����ID�i�[
      <<m_line_id_data_loop>>
      FOR i IN 1..gt_mov_line.COUNT LOOP
        -- LOOP�J�E���g�p�ϐ��փJ�E���g���}��
        gn_m_id_cnt := i;
--
        gt_mod_line_id(gn_m_id_cnt) := gt_mov_line(i).m_line_id;  -- �ړ�����ID
      END LOOP m_line_id_data_loop;
--
      -- �ړ��w���Ώۃf�[�^���o�Ŏ擾�����ړ�����ID�ɑΉ������ړ����b�h�ڍׂ��ꊇ�폜
      FORALL m_id_cnt IN 1 .. gt_mod_line_id.COUNT
        DELETE
        FROM xxinv_mov_lot_details  xmld    -- �ړ����b�g�ڍׁi�A�h�I���j
        WHERE xmld.mov_line_id        = gt_mod_line_id(m_id_cnt)  -- �󒍖��׃A�h�I��ID
        AND   xmld.document_type_code = gv_move_req               -- �����^�C�v�u�ړ��w���v
        ;
--
      -- �폜�������J�E���g
-- 2008/06/03 START �J�[�\���ŏ�������Ȃ��ꍇSQL%rowcount�͑O��SQL�̏���������
-- �\�����邽�ߏ�L�J�[�\�������s���ꂽ�ꍇ�̂ݎ��s����悤�ɏ�����ǉ�
      -- �Ώۂ̈ړ�����ID���ꌏ�ȏ�̏ꍇ�폜���������Z
      IF (gt_mod_line_id.COUNT >= 1) THEN
        ln_cnt := SQL%rowcount;
        gn_del_cut := gn_del_cut + ln_cnt;
      END IF;
-- 2008/06/03 END
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_del_mov_lot;
--
  /**********************************************************************************
   * Procedure Name   : pro_upd_o_lines
   * Description      : �󒍖��׃A�h�I���X�V  (G-5)
   ***********************************************************************************/
  PROCEDURE pro_upd_o_lines
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_upd_o_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_cnt  NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
     -- �󒍖��׃A�h�I���̍X�V�����{
     FORALL i IN 1 .. gt_l_order_line_id.COUNT
       UPDATE xxwsh_order_lines_all         xola    -- �󒍖��׃A�h�I��
       SET xola.reserved_quantity        = 0                 -- ������
          ,xola.automanual_reserve_class = NULL              -- �����蓮�����敪
          ,xola.warning_class            = NULL              -- �x���敪
          ,xola.warning_date             = NULL              -- �x�����t
          ,xola.last_updated_by          = gn_last_upd_by    -- �ŏI�X�V��
          ,xola.last_update_date         = gd_last_upd_date  -- �ŏI�X�V��
          ,xola.last_update_login        = gn_last_upd_login -- �ŏI�X�V���O�C��
          ,xola.request_id               = gn_request_id     -- �v��ID
          ,xola.program_application_id   = gn_prog_appl_id   -- �R���J�����g�E�v���O�����E�A�v��ID
          ,xola.program_id               = gn_prog_id        -- �R���J�����g�E�v���O����ID
       WHERE xola.order_line_id   = gt_l_order_line_id(i)  -- �󒍖��׃A�h�I��ID
       ;
--
     -- ���������J�E���g
-- 2008/06/03 START �J�[�\���ŏ�������Ȃ��ꍇSQL%rowcount�͑O��SQL�̏���������
-- �\�����邽�ߏ�L�J�[�\�������s���ꂽ�ꍇ�̂ݎ��s����悤�ɏ�����ǉ�
    IF ( gt_l_order_line_id.COUNT >= 1 ) THEN
      ln_cnt        := SQL%rowcount;
      gn_target_cnt := gn_target_cnt + ln_cnt;
    END IF;
-- 2008/06/03 END
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_upd_o_lines;
--
  /**********************************************************************************
   * Procedure Name   : pro_upd_m_r_lines
   * Description      : �ړ��˗�/�w�����ׁi�A�h�I���j�X�V (G-6)
   ***********************************************************************************/
  PROCEDURE pro_upd_m_r_lines
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_upd_m_r_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_cnt  NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
   -- �ړ��˗�/�w�����ׁi�A�h�I���j�̍X�V�����{
   FORALL i IN 1 .. gt_mod_line_id.COUNT
     UPDATE xxinv_mov_req_instr_lines     xmril   -- �ړ��˗�/�w�����ׁi�A�h�I���j
     SET xmril.reserved_quantity        = 0                 -- ������
        ,xmril.automanual_reserve_class = NULL              -- �����蓮�����敪
        ,xmril.warning_class            = NULL              -- �x���敪
        ,xmril.warning_date             = NULL              -- �x�����t
        ,xmril.last_updated_by          = gn_last_upd_by    -- �ŏI�X�V��
        ,xmril.last_update_date         = gd_last_upd_date  -- �ŏI�X�V��
        ,xmril.last_update_login        = gn_last_upd_login -- �ŏI�X�V���O�C��
        ,xmril.request_id               = gn_request_id     -- �v��ID
        ,xmril.program_application_id   = gn_prog_appl_id   -- �R���J�����g�E�v���O�����E�A�v��ID
        ,xmril.program_id               = gn_prog_id        -- �R���J�����g�E�v���O����ID
     WHERE xmril.mov_line_id   = gt_mod_line_id(i)  -- �ړ�����ID
     ;
--
     -- ���������J�E���g
-- 2008/06/03 START �J�[�\���ŏ�������Ȃ��ꍇSQL%rowcount�͑O��SQL�̏���������
-- �\�����邽�ߏ�L�J�[�\�������s���ꂽ�ꍇ�̂ݎ��s����悤�ɏ�����ǉ�
    IF ( gt_mod_line_id.COUNT >= 1 ) THEN
      ln_cnt        := SQL%rowcount;
      gn_target_cnt := gn_target_cnt + ln_cnt;
    END IF;
-- 2008/06/03 END
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_upd_m_r_lines;
--
  /**********************************************************************************
   * Procedure Name   : pro_out_msg
   * Description      : ���b�Z�[�W�o��  (G-7)
   ***********************************************************************************/
  PROCEDURE pro_out_msg
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_out_msg'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ړ����b�g�ڍׁi�A�h�I���j�ɂč폜�������������b�Z�[�W�o��
    gv_out_msg := xxcmn_common_pkg.get_msg( gv_application       -- 'XXWSH'
                                           ,gv_err_del_count     -- �폜�������b�Z�[�W
                                           ,gv_tkn_count         -- �g�[�N��
                                           ,gn_del_cut           -- �폜����
                                           );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_out_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_item_class          IN  VARCHAR2   -- 1.���i�敪
     ,iv_action_type         IN  VARCHAR2   -- 2.�������
     ,iv_block1              IN  VARCHAR2   -- 3.�u���b�N�P
     ,iv_block2              IN  VARCHAR2   -- 4.�u���b�N�Q
     ,iv_block3              IN  VARCHAR2   -- 5.�u���b�N�R
     ,iv_deliver_from_id     IN  VARCHAR2   -- 6.�o�Ɍ�
     ,iv_deliver_type        IN  VARCHAR2   -- 7.�o�Ɍ`��
     ,iv_deliver_date_from   IN  VARCHAR2   -- 8.�o�ɓ�From
     ,iv_deliver_date_to     IN  VARCHAR2   -- 9.�o�ɓ�To
     ,ov_errbuf              OUT VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT VARCHAR2   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- �p�����[�^�i�[
    gr_param.item_class   := iv_item_class;              -- ���i�敪
    gr_param.action_type  := iv_action_type;             -- �������
    gr_param.block1       := iv_block1;                  -- �u���b�N�P
    gr_param.block2       := iv_block2;                  -- �u���b�N�Q
    gr_param.block3       := iv_block3;                  -- �u���b�N�R
    gr_param.del_from_id  := iv_deliver_from_id;         -- �o�Ɍ�
    gr_param.del_type     := iv_deliver_type;            -- �o�Ɍ`��
    gr_param.del_d_from   := iv_deliver_date_from;       -- �o�ɓ�From
    gr_param.del_d_to     := iv_deliver_date_to;         -- �o�ɓ�To
--
    -- �J�n���̃V�X�e�����ݓ��t����
    gd_sysdate             := SYSDATE;
--
    -- �v�g�n�J�����擾
    gn_last_upd_by         := FND_GLOBAL.USER_ID;         -- �ŏI�X�V��
    gd_last_upd_date       := gd_sysdate;                 -- �ŏI�X�V��
    gn_last_upd_login      := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gn_request_id          := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gn_prog_appl_id        := FND_GLOBAL.PROG_APPL_ID;    -- �v���O�����A�v���P�[�V����ID
    gn_prog_id             := FND_GLOBAL.CONC_PROGRAM_ID; -- �v���O����ID
--
    -- ��������������
    gn_target_cnt          := 0;
--
    -- =====================================================
    --  ���̓p�����[�^�`�F�b�N (G-1)
    -- =====================================================
    pro_param_chk
      (
        ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���͂o�u������ʁv���w�o�׈˗��x���w�w��Ȃ�(ALL)�x�̏ꍇ����s
    IF ((gr_param.action_type = gv_s_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  �o�׈˗��Ώۃf�[�^���o (G-2)
      -- =====================================================
      pro_get_h_o_all
        (
          ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ���͂o�u������ʁv���w�ړ��w���˗��x���w�w��Ȃ�(ALL)�x�̏ꍇ����s
    IF ((gr_param.action_type = gv_m_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  �ړ��w���Ώۃf�[�^���o (G-3)
      -- =====================================================
      pro_get_mov_req
        (
          ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    --  �ړ����b�h�ڍׁi�A�h�I���j�폜 (G-4)
    -- =====================================================
    pro_del_mov_lot
      (
        ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���͂o�u������ʁv���w�o�׈˗��x���w�w��Ȃ�(ALL)�x�̏ꍇ����s
    IF ((gr_param.action_type = gv_s_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  �󒍖��׃A�h�I���X�V (G-5)
      -- =====================================================
      pro_upd_o_lines
        (
          ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ���͂o�u������ʁv���w�ړ��w���˗��x���w�w��Ȃ�(ALL)�x�̏ꍇ����s
    IF ((gr_param.action_type = gv_m_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  �ړ��˗�/�w�����ׁi�A�h�I���j�X�V (G-6)
      -- =====================================================
      pro_upd_m_r_lines
        (
          ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    --  ���b�Z�[�W�o�� (G-7)
    -- =====================================================
    pro_out_msg
      (
        ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
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
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
     ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
     ,iv_item_class         IN  VARCHAR2      -- 1.���i�敪
     ,iv_action_type        IN  VARCHAR2      -- 2.�������
     ,iv_block1             IN  VARCHAR2      -- 3.�u���b�N�P
     ,iv_block2             IN  VARCHAR2      -- 4.�u���b�N�Q
     ,iv_block3             IN  VARCHAR2      -- 5.�u���b�N�R
     ,iv_deliver_from_id    IN  VARCHAR2      -- 6.�o�Ɍ�
     ,iv_deliver_type       IN  VARCHAR2      -- 7.�o�Ɍ`��
     ,iv_deliver_date_from  IN  VARCHAR2      -- 8.�o�ɓ�From
     ,iv_deliver_date_to    IN  VARCHAR2      -- 9.�o�ɓ�To
    )
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
-- 2008/06/03 START
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
-- 2008/06/03 END
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -----------------------------------------------
    -- ���̓p�����[�^�o��                        --
    -----------------------------------------------
    -- ���̓p�����[�^�u���i�敪�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12955','ITEM',iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u������ʁv�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12956','AC_TYPE',iv_action_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N1�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12957','IN_BLOCK1',iv_block1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N2�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12958','IN_BLOCK2',iv_block2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�u���b�N3�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12959','IN_BLOCK3',iv_block3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�Ɍ��v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12960','FROM_ID',iv_deliver_from_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�Ɍ`�ԁv�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12961','TYPE',iv_deliver_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�ɓ�From�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12962','D_FROM',iv_deliver_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�o�ɓ�To�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12963','D_TO',iv_deliver_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain
      (
        iv_item_class        => iv_item_class         -- 1.���i�敪
       ,iv_action_type       => iv_action_type        -- 2.�������
       ,iv_block1            => iv_block1             -- 3.�u���b�N�P
       ,iv_block2            => iv_block2             -- 4.�u���b�N�Q
       ,iv_block3            => iv_block3             -- 5.�u���b�N�R
       ,iv_deliver_from_id   => iv_deliver_from_id    -- 6.�o�Ɍ�
       ,iv_deliver_type      => iv_deliver_type       -- 7.�o�Ɍ`��
       ,iv_deliver_date_from => iv_deliver_date_from  -- 8.�o�ɓ�From
       ,iv_deliver_date_to   => iv_deliver_date_to    -- 9.�o�ɓ�To
       ,ov_errbuf            => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
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
      ELSIF (lv_errbuf IS NULL) THEN
        --���[�U�[�E�G���[�E���b�Z�[�W�̃R�s�[
        lv_errbuf := lv_errmsg;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = USERENV('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type
                                                                     ,flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
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
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh920002c;
/
