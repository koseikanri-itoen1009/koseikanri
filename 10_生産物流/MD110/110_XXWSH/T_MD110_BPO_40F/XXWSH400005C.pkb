CREATE OR REPLACE PACKAGE BODY xxwsh400005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400005C(body)
 * Description      : �o�׈˗���񒊏o
 * MD.050           : �o�׈˗�         T_MD050_BPO_401
 * MD.070           : �o�׈˗���񒊏o T_MD070_BPO_40F
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  cutoff_str             ������𖖔�����؂���
 *  if_flg_upd             I/F�σt���O�̍X�V
 *  tbl_lock               �e�[�u���̃��b�N�̎擾
 *  get_request_class      �˗��敪�̎擾
 *  get_results_data       �o�׎��я��̎擾
 *  get_request_data       �o�׈˗����̎擾
 *  parameter_check        �p�����[�^�`�F�b�N                           (F-1)
 *  get_profile            �v���t�@�C���擾                             (F-2)
 *  get_obj_data           �o�׈˗���񒊏o                             (F-3)
 *  put_obj_data           �o�׈˗����o��                             (F-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/01    1.0   Oracle �R�� ��_ ����쐬
 *  2008/05/30    1.1   Oracle �Γn ���a �o�׈˗�(����)�o�͍ς݃t���O�̔���C��
 *  2008/06/10    1.2   Oracle �Γn ���a TE080�w�E�����C��
 *  2008/07/14    1.3   Oracle �Ŗ� ���\ TE080�w�E����#73�Ή�
 *  2008/08/04    1.4   Oracle �R�� ��_ ST#103�Ή�
 *  2008/08/22    1.5   Oracle �R�� ��_ T_S_597�Ή�
 *  2008/09/04    1.6   Oracle �R�� ��_ PT 3-3_23 �w�E37�Ή�
 *  2008/09/18    1.7   Oracle �ɓ� �ЂƂ� T_TE080_BPO_400 �w�E79,T_S_630�Ή�
 *  2008/11/06    1.8   SCS    �ɓ� �ЂƂ� �����e�X�g�w�E560�Ή�
 *  2008/12/01    1.9   SCS    �g�c �Ď� �{��#291�Ή�
 *  2008/12/03    1.10  SCS    �{�c      �{��#255�Ή�
 *  2008/12/24    1.11  SCS    �Ŗ� ���\ �{��#827�Ή�
 *  2009/01/21    1.12  SCS    �㌴ ���D �{��#1010�Ή�
 *  2009/05/22    1.13  SCS    �ɓ� �ЂƂ� �{��#1398�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
-- 2008/09/18 1.17 Add �� T_TE080_BPO_400 �w�E79
  gv_status_skip   CONSTANT VARCHAR2(1) := '3';
-- 2008/09/18 1.17 Add ��
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  get_profile_expt          EXCEPTION;     -- �v���t�@�C���擾�G���[
  lock_expt                 EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh400005c';  -- �p�b�P�[�W��
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXWSH';         -- �A�v���P�[�V�����Z�k��
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';         -- �A�v���P�[�V�����Z�k��
--
  gv_tkn_num_40f_01    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11251';  -- �p�����[�^�����̓G���[
  gv_tkn_num_40f_02    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11252';  -- �Ώۃf�[�^0���G���[
  gv_tkn_num_40f_03    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11253';  -- ���̓p�����[�^���͒l�G���[
  gv_tkn_num_40f_04    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11254';  -- �v���t�@�C���擾�G���[
  gv_tkn_num_40f_05    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11255';  -- �˗��敪�擾�G���[
  gv_tkn_num_40f_06    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11256';  -- �˗�No�R���o�[�g�G���[
  gv_tkn_num_40f_07    CONSTANT VARCHAR2(15) := 'APP-XXWSH-11704';  -- �t�@�C���A�N�Z�X�����G���[
  gv_tkn_num_40f_08    CONSTANT VARCHAR2(15) := 'APP-XXWSH-10006';  -- ���b�N�����G���[
--
  gv_tkn_parameter     CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_tkn_prof_name     CONSTANT VARCHAR2(15) := 'PROF_NAME';
  gv_type_name         CONSTANT VARCHAR2(15) := 'TYPE_NAME';
--
  gv_inf_sub_request   CONSTANT VARCHAR2(1)  := '1';    -- �o�׈˗�
  gv_inf_sub_results   CONSTANT VARCHAR2(1)  := '2';    -- �o�׎���
  gv_adjs_class_req    CONSTANT VARCHAR2(1)  := '1';    -- �o�׈˗�
  gv_adjs_class_adj    CONSTANT VARCHAR2(1)  := '2';    -- �݌ɒ���
--
  gv_req_status_03     CONSTANT VARCHAR2(2)  := '03';   -- ���ߍς�
  gv_req_status_04     CONSTANT VARCHAR2(2)  := '04';   -- �o�׎��ьv���
  gv_req_status_99     CONSTANT VARCHAR2(2)  := '99';   -- ���
--
  gv_flag_on           CONSTANT VARCHAR2(1)  := 'Y';
  gv_flag_off          CONSTANT VARCHAR2(1)  := 'N';
--
  gv_data_div          CONSTANT VARCHAR2(3)  := '440';     -- �f�[�^���
  gv_r_no              CONSTANT VARCHAR2(1)  := '0';       -- R_No
  gv_continue          CONSTANT VARCHAR2(2)  := '00';      -- �p��
  gv_num_zero          CONSTANT VARCHAR2(1)  := '0';
  gv_prod_class_reef   CONSTANT VARCHAR2(1)  := '1';       -- ���[�t
  gv_prod_class_drink  CONSTANT VARCHAR2(1)  := '2';       -- �h�����N
  gv_base_code_reef    CONSTANT VARCHAR2(4)  := '2020';    -- ���[�t
  gv_base_code_drink   CONSTANT VARCHAR2(4)  := '2100';    -- �h�����N
  gv_max_date          CONSTANT VARCHAR2(6)  := '999999';
  gv_tran_type_name    CONSTANT VARCHAR2(20) := '�o�׈˗�';
  gv_category_code     CONSTANT VARCHAR2(20) := 'ORDER';
-- 2008/09/18 1.17 Add �� T_TE080_BPO_400 �w�E79
  gv_shipping_shikyu_class_1 CONSTANT VARCHAR2(1)  := '1';         -- �o�׎x���敪:�o�׈˗�
  gv_cust_class_code_10      CONSTANT VARCHAR2(2)  := '10';        -- �ڋq�敪:�ڋq�z��
  gv_dummy_cust_code         CONSTANT VARCHAR2(9)  := '000000000'; -- �ڋq�R�[�h(�_�~�[)
-- 2008/09/18 1.17 Add ��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  TYPE masters_rec IS RECORD(
    deliver_from          xxwsh_order_headers_all.deliver_from%TYPE,      -- �o�׌�
    head_sales_branch     xxwsh_order_headers_all.head_sales_branch%TYPE, -- �Ǌ����_
-- 2008/07/14 1.3 Update Start
--    prod_class_code       xxcmn_item_categories3_v.prod_class_code%TYPE,  -- ���i�敪
    prod_class_h_code     mtl_categories_b.segment1%TYPE,                 -- �{�Џ��i�敪
-- 2008/07/14 1.3 Update End
    order_type_id         xxwsh_order_headers_all.order_type_id%TYPE,     -- �󒍃^�C�vID
    arrival_date          xxwsh_order_headers_all.arrival_date%TYPE,      -- ���ד�
    deliver_to            xxwsh_order_headers_all.deliver_to%TYPE,        -- �o�א�
    customer_code         xxwsh_order_headers_all.customer_code%TYPE,     -- �ڋq
    request_no            xxwsh_order_headers_all.request_no%TYPE,        -- �˗�No
    order_line_id         xxwsh_order_lines_all.order_line_id%TYPE,       -- �󒍖��׃A�h�I��ID
    request_item_code     xxwsh_order_lines_all.request_item_code%TYPE,   -- �˗��i��
    quantity              xxwsh_order_lines_all.quantity%TYPE,            -- ����
    num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE,             -- �P�[�X����
    delete_flag           xxwsh_order_lines_all.delete_flag%TYPE,         -- �폜�t���O
    cust_po_number        xxwsh_order_headers_all.cust_po_number%TYPE,    -- �ڋq�����ԍ�
    shipped_date          xxwsh_order_headers_all.shipped_date%TYPE,      -- �o�ד�
    arrival_time_from     xxwsh_order_headers_all.arrival_time_from%TYPE, -- ���׎���From
    item_no               xxcmn_item_mst_v.item_no%TYPE,                  -- �e�i��
-- 2008/12/24 v2.1 UPDATE START
--    new_crowd_code        xxcmn_item_mst2_v.new_crowd_code%TYPE,          -- �V�E�Q�R�[�h
    crowd_code            VARCHAR2(240),                                    -- �Q�R�[�h
-- 2008/12/24 v2.1 UPDATE END
    shipped_quantity      xxwsh_order_lines_all.shipped_quantity%TYPE,    -- �o�׎��ѐ���
--
    request_class         xxwsh_shipping_class_v.request_class%TYPE,      -- �˗��敪
--
    cases_values          NUMBER,                                         -- �P�[�X����
--
    -- YYYY/MM/DD
    vd_arrival_date       VARCHAR2(10),                                   -- ���ד�
    vd_shipped_date       VARCHAR2(10),                                   -- �o�ד�
--
    -- YYYYMMDD
    v_arrival_date        VARCHAR2(10),                                   -- ���ד�
    v_shipped_date        VARCHAR2(10),                                   -- �o�ד�
--
-- 2008/09/18 1.17 Add �� T_S_630
    customer_class_code  xxcmn_cust_accounts2_v.customer_class_code%TYPE, -- �ڋq���VIEW.�ڋq�敪
-- 2008/09/18 1.17 Add ��
    exec_flg              NUMBER                                    -- �����t���O
  );
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
  TYPE reg_order_line_id IS TABLE OF
       xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
--
  gt_master_tbl           masters_tbl;  -- �e�}�X�^�֓o�^����f�[�^
--
  gt_order_line_id        reg_order_line_id;           -- �󒍖��׃A�h�I��ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_request_path         VARCHAR2(2000);     -- �f�B���N�g��(�o�׈˗�)
  gv_request_file         VARCHAR2(2000);     -- �t�@�C����(�o�׈˗�)
  gv_results_path         VARCHAR2(2000);     -- �f�B���N�g��(�o�׎���)
  gv_results_file         VARCHAR2(2000);     -- �t�@�C����(�o�׎���)
--
  -- �萔
  gn_created_by               NUMBER;                     -- �쐬��
  gd_creation_date            DATE;                       -- �쐬��
  gd_last_update_date         DATE;                       -- �ŏI�X�V��
  gn_last_update_by           NUMBER;                     -- �ŏI�X�V��
  gn_last_update_login        NUMBER;                     -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER;                     -- �v��ID
  gn_program_application_id   NUMBER;                     -- �v���O�����A�v���P�[�V����ID
  gn_program_id               NUMBER;                     -- �v���O����ID
  gd_program_update_date      DATE;                       -- �v���O�����X�V��
--
-- 2008/12/24 ADD START
  gv_sysdate                  VARCHAR2(240);  -- �V�X�e�����ݓ��t
--
-- 2008/12/24 ADD END
  /***********************************************************************************
   * Function Name    : cutoff_str
   * Description      : ������𖖔�����؂���
   ***********************************************************************************/
  FUNCTION cutoff_str(
    iv_str  IN VARCHAR2,     -- �Ώە�����
    in_len  IN NUMBER,       -- ����
    in_size IN NUMBER)       -- �T�C�Y
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cutoff_str'; --�v���O������
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
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
--
    RETURN SUBSTR(iv_str,in_len-in_size+1,in_size);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END cutoff_str;
--
  /***********************************************************************************
   * Procedure Name   : if_flg_upd
   * Description      : I/F�σt���O�̍X�V
   ***********************************************************************************/
  PROCEDURE if_flg_upd(
    iv_inf_div    IN            VARCHAR2,     -- 1.�C���^�t�F�[�X�Ώ�
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'if_flg_upd'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �o�׈˗�
    IF (iv_inf_div = gv_inf_sub_request) THEN
      FORALL item_cnt IN 1 .. gt_order_line_id.COUNT
        UPDATE xxwsh_order_lines_all
        SET  shipping_request_if_flg = gv_flag_on                    -- �o�׈˗�I/F�σt���O
            ,last_updated_by         = gn_last_update_by
            ,last_update_date        = gd_last_update_date
            ,last_update_login       = gn_last_update_login
            ,request_id              = gn_request_id
            ,program_application_id  = gn_program_application_id
            ,program_id              = gn_program_id
            ,program_update_date     = gd_program_update_date
        WHERE order_line_id = gt_order_line_id(item_cnt);
--
    -- �o�׎���
    ELSIF (iv_inf_div = gv_inf_sub_results) THEN
      FORALL item_cnt IN 1 .. gt_order_line_id.COUNT
        UPDATE xxwsh_order_lines_all
        SET  shipping_result_if_flg  = gv_flag_on                    -- �o�׎���I/F�σt���O
            ,last_updated_by         = gn_last_update_by
            ,last_update_date        = gd_last_update_date
            ,last_update_login       = gn_last_update_login
            ,request_id              = gn_request_id
            ,program_application_id  = gn_program_application_id
            ,program_id              = gn_program_id
            ,program_update_date     = gd_program_update_date
        WHERE order_line_id = gt_order_line_id(item_cnt);
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END if_flg_upd;
--
  /***********************************************************************************
   * Procedure Name   : tbl_lock
   * Description      : �e�[�u���̃��b�N�̎擾
   ***********************************************************************************/
  PROCEDURE tbl_lock(
    ir_mst_rec    IN OUT NOCOPY masters_rec,  -- �Ώۃf�[�^
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'tbl_lock'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_order_line_id     xxwsh_order_lines_all.order_line_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
--
    -- �󒍖��׃A�h�I���̃��b�N
    BEGIN
      SELECT xola.order_line_id
      INTO   ln_order_line_id
      FROM   xxwsh_order_lines_all xola
      WHERE  xola.order_line_id = ir_mst_rec.order_line_id
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_08);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END tbl_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_request_class
   * Description      : �˗��敪�̎擾
   ***********************************************************************************/
  PROCEDURE get_request_class(
    ir_mst_rec    IN OUT NOCOPY masters_rec,  -- �Ώۃf�[�^
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_request_class'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
-- 2008/09/18 1.17 Add �� T_TE080_BPO_400 �w�E79 �o�׋敪���VIEW.�˗��敪�Əo�׋敪���VIEW.�ڋq�敪���擾���A����NULL�̏ꍇ��CSV�o�͂��Ȃ��B
    lt_customer_class   xxwsh_shipping_class_v.customer_class%TYPE; -- �o�׋敪���VIEW�̌ڋq�敪
-- 2008/09/18 1.17 Add ��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    BEGIN
-- 2008/09/18 1.17 Mod �� T_TE080_BPO_400 �w�E79 �o�׋敪���VIEW.�˗��敪�Əo�׋敪���VIEW.�ڋq�敪���擾���A����NULL�̏ꍇ��CSV�o�͂��Ȃ��悤�ɕύX
--                        T_S_630                �ڋq���VIEW.�ڋq�敪�͕ʉӏ��ł̎擾�ƂȂ����̂ŁA�˗��敪�̎擾�Ɍڋq���VIEW�̌����͕s�v�ƂȂ���
--      SELECT xscv.request_class                     -- �˗��敪
--      INTO   ir_mst_rec.request_class
--      FROM   xxwsh_oe_transaction_types2_v xottv        -- �󒍃^�C�v���VIEW2
--            ,xxwsh_shipping_class_v        xscv         -- �o�׋敪���VIEW
----            ,hz_parties                    hp           -- �p�[�e�B�}�X�^
----            ,hz_party_sites                hps          -- �p�[�e�B�T�C�g�}�X�^
----            ,hz_cust_accounts              hca          -- �ڋq�}�X�^
--            ,xxcmn_cust_accounts2_v          xcav       -- �ڋq���View2
--            ,xxcmn_cust_acct_sites2_v        xcasv      -- �ڋq�T�C�g���View2
--      WHERE  xscv.order_transaction_type_name = xottv.transaction_type_name
----      AND    hp.party_id                      = hps.party_id
----      AND    hca.party_id                     = hp.party_id
----      AND    hca.customer_class_code          = xscv.customer_class(+)
----      AND    hps.party_site_number            = ir_mst_rec.deliver_to
--      AND    xcav.customer_class_code         = xscv.customer_class(+)
--      AND    xcav.start_date_active          <= ir_mst_rec.shipped_date
--      AND    xcav.end_date_active            >= ir_mst_rec.shipped_date
--      AND    xcasv.party_id                   = xcav.party_id
--      AND    xcasv.start_date_active         <= ir_mst_rec.shipped_date
--      AND    xcasv.end_date_active           >= ir_mst_rec.shipped_date
--      AND    xcasv.party_site_number          = ir_mst_rec.deliver_to
--      AND    xottv.transaction_type_id        = ir_mst_rec.order_type_id
--      AND    xottv.shipping_shikyu_class      = '1'                        -- �o�׈˗�
--      AND    ROWNUM                           = 1;
--
      SELECT xscv.request_class         request_class   -- �˗��敪
            ,xscv.customer_class        customer_class  -- �ڋq�敪
      INTO   ir_mst_rec.request_class
            ,lt_customer_class
      FROM   xxwsh_oe_transaction_types2_v xottv        -- �󒍃^�C�v���VIEW2
            ,xxwsh_shipping_class_v        xscv         -- �o�׋敪���VIEW
      WHERE  -- *** �������� �󒍃^�C�v���VIEW2 AND �o�׋敪���VIEW *** --
             xscv.order_transaction_type_name = xottv.transaction_type_name
             -- *** ���o���� *** --
      AND    NVL(xscv.customer_class, ir_mst_rec.customer_class_code)
                                              = ir_mst_rec.customer_class_code  -- �o�׋敪���VIEW.�ڋq�敪(�o�׋敪���VIEW.�ڋq�敪��NULL�̏ꍇ�͌ڋq�敪�������Ƃ��Ȃ�)
      AND    xottv.transaction_type_id        = ir_mst_rec.order_type_id        -- �󒍃^�C�v
      AND    xottv.shipping_shikyu_class      = gv_shipping_shikyu_class_1      -- �o�׎x���敪�u1�F�o�׈˗��v
      AND    ROWNUM                           = 1;
-- 2008/09/18 1.17 Mod ��
--
-- 2008/09/18 1.17 Add �� T_TE080_BPO_400 �w�E79
    -- �o�׋敪���VIEW.�˗��敪�Əo�׋敪���VIEW.�ڋq�敪���擾���A����NULL�̏ꍇ��CSV�o�͂��Ȃ��B
    IF ((ir_mst_rec.request_class IS NULL)
    AND (lt_customer_class IS NULL)) THEN
      ov_retcode := gv_status_skip;
    END IF;
-- 2008/09/18 1.17 Add ��
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_mst_rec.request_class := NULL;
        ov_retcode := gv_status_warn;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_request_class;
--
  /***********************************************************************************
   * Procedure Name   : get_results_data
   * Description      : �o�׎��я��̎擾
   ***********************************************************************************/
  PROCEDURE get_results_data(
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_results_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt               NUMBER;
    mst_rec              masters_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
-- 2008/09/04 Mod ��
/*
      SELECT xoha.arrival_date                   -- ���ד�
*/
      SELECT /*+ leading(xola xoha) use_nl(xoha xola ximb ximv1.iimb ximv2.iimb ) */
             xoha.arrival_date                   -- ���ד�
-- 2008/09/04 Mod ��
            ,xoha.head_sales_branch              -- �Ǌ����_
-- 2008/09/18 1.17 Add �� T_S_630
            ,xoha.order_type_id                  -- �󒍃^�C�vID
            ,xoha.shipped_date                   -- �o�ד�
-- 2008/09/18 1.17 Add ��
            ,xoha.result_deliver_to              -- �o�א�_����
            ,xoha.customer_code                  -- �ڋq
            ,xoha.request_no                     -- �˗�No
            ,xola.order_line_id                  -- �󒍖��׃A�h�I��ID
            ,xola.request_item_code              -- �˗��i��
-- 2008/12/01 1.9  Mod ��
            ,CASE WHEN otta.order_category_code   = gv_category_code
                  THEN xola.shipped_quantity
                  ELSE xola.shipped_quantity * (-1)
             END  shipped_quantity
            --,xola.shipped_quantity               -- �o�׎��ѐ���
-- 2008/12/01 1.9  Mod ��
            ,xola.delete_flag                    -- �폜�t���O
            ,ximv1.item_no                       -- �e�i��
-- 2008/12/24 v2.1 UPDATE START
--            ,ximv2.new_crowd_code                -- �V�E�Q�R�[�h
            ,CASE
              WHEN NVL(ximv2.crowd_start_date, gv_sysdate) <= gv_sysdate THEN
                ximv2.new_crowd_code             -- �V�E�Q�R�[�h
              ELSE
                ximv2.old_crowd_code             -- ���E�Q�R�[�h
             END crowd_code
-- 2008/12/24 v2.1 UPDATE END
            ,ximv2.num_of_cases                  -- �P�[�X����
-- 2008/07/14 1.3 Update Start
--            ,xic4.prod_class_code                -- ���i�敪
-- 2008/09/04 Mod ��
--            ,xicv2.prod_class_h_code             -- �{�Џ��i�敪
-- 2008/07/14 1.3 Update End
            ,(
             SELECT MAX(CASE
                        WHEN xicv.category_set_name = '�{�Џ��i�敪' THEN
                          mcb.segment1
                        ELSE
                          NULL
                    END) as prod_class_h_code 
             FROM   xxcmn_item_categories_v xicv 
                  , mtl_categories_b mcb 
             WHERE  xicv.category_id  = mcb.category_id 
             AND    xicv.structure_id = mcb.structure_id 
             AND    xicv.item_id      = ximv2.item_id
             ) prod_class_h_code
-- 2008/09/04 Mod ��
      FROM   xxwsh_order_headers_all       xoha          -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all         xola          -- �󒍖��׃A�h�I��
            ,xxwsh_oe_transaction_types2_v otta          -- �󒍃^�C�v���VIEW
            ,xxcmn_item_mst2_v             ximv1         -- OPM�i�ڃ}�X�^(�e)
            ,xxcmn_item_mst2_v             ximv2         -- OPM�i�ڃ}�X�^(�q)
            ,xxcmn_item_mst_b              ximb          -- OPM�i�ڃA�h�I���}�X�^
-- 2008/07/14 1.3 Update Start
--            ,xxcmn_item_categories4_v      xic4          -- OPM�i�ڃJ�e�S���������VIEW4
-- 2008/09/04 Del ��
/*
            ,(SELECT  xicv.item_id
                     ,MAX(CASE
                        WHEN xicv.category_set_name = '�{�Џ��i�敪' THEN
                          mcb.segment1
                        ELSE
                          NULL
                      END) AS prod_class_h_code          -- �{�Џ��i�敪
            FROM      xxcmn_item_categories_v   xicv     -- OPM�i�ڃJ�e�S���������VIEW
                     ,mtl_categories_b          mcb
            WHERE     xicv.category_id  = mcb.category_id
            AND       xicv.structure_id = mcb.structure_id
            GROUP BY  xicv.item_id) xicv2
*/
-- 2008/09/04 Del ��
-- 2008/07/14 1.3 Update End
      WHERE  xoha.order_header_id       = xola.order_header_id
      AND    xoha.order_type_id         = otta.transaction_type_id
      AND    ximv2.item_no              = xola.request_item_code
      AND    ximb.item_id               = ximv2.item_id
      AND    ximb.parent_item_id        = ximv1.item_id
      AND    ximb.start_date_active    <= xoha.shipped_date
      AND    ximb.end_date_active      >= xoha.shipped_date
-- 2008/12/01 1.9  Mod ��
      AND    ximv1.start_date_active    <= xoha.shipped_date
      AND    ximv1.end_date_active      >= xoha.shipped_date
      AND    ximv2.start_date_active    <= xoha.shipped_date
      AND    ximv2.end_date_active      >= xoha.shipped_date
-- 2008/12/01 1.9  Mod ��
-- 2008/07/14 1.3 Update Start
--      AND    ximv2.item_id              = xic4.item_id
-- 2008/09/04 Del ��
--      AND    ximv2.item_id              = xicv2.item_id
-- 2008/09/04 Del ��
-- 2008/07/14 1.3 Update End
      AND    xoha.req_status            = gv_req_status_04                  -- �o�׎��ьv���
-- 2008/09/18 1.17 Mod �� T_TE080_BPO_400 �w�E79 �o�׈˗��ȊO�̏o�׃f�[�^�����o�ΏۂƂ���B
--      AND    otta.transaction_type_name = gv_tran_type_name               -- �o�׈˗�
      AND    otta.shipping_shikyu_class = gv_shipping_shikyu_class_1        -- �o�׎x���敪���u1�F�o�׈˗��v
-- 2008/09/18 1.17 Mod ��
-- 2008/12/01 1.9  Mod ��
--    AND    otta.order_category_code   = gv_category_code                  -- ��
-- 2008/12/01 1.9  Mod ��
      AND    NVL(otta.adjs_class,gv_adjs_class_req) <> gv_adjs_class_adj    -- �݌ɒ����ȊO
      AND    NVL(xola.shipping_result_if_flg, gv_flag_off )  = gv_flag_off  -- �o�͍ς݈ȊO
-- 2009/01/21 2.2 Add start
      AND    xoha.actual_confirm_class = gv_flag_on                         -- ���ьv��ϋ敪��'Y'
-- 2009/01/21 2.2 Add end
      ORDER BY xoha.request_no,xola.request_item_code;
--
    -- *** ���[�J���E���R�[�h ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.arrival_date      := lr_mst_data_rec.arrival_date;       -- ���ד�
      mst_rec.head_sales_branch := lr_mst_data_rec.head_sales_branch;  -- �Ǌ����_
-- 2008/09/18 1.17 Add �� T_S_630
      mst_rec.order_type_id     := lr_mst_data_rec.order_type_id;      -- �󒍃^�C�vID
      mst_rec.shipped_date      := lr_mst_data_rec.shipped_date;       -- �o�ד�
-- 2008/09/18 1.17 Add ��
      mst_rec.deliver_to        := lr_mst_data_rec.result_deliver_to;  -- �o�א�_����
-- 2008/09/18 1.17 Mod �� T_S_630 �ڋq�敪�ɂ��ڋq�R�[�h������
--      mst_rec.customer_code     := lr_mst_data_rec.customer_code;      -- �ڋq
--
      -- �ڋq�敪�擾
      SELECT xcav.customer_class_code                   -- �ڋq�敪
-- 2009/05/22 H.Itou Add Start �{�ԏ�Q#1398
            ,xcav.party_number                          -- �ڋq
-- 2009/05/22 H.Itou Add End
      INTO   mst_rec.customer_class_code
-- 2009/05/22 H.Itou Add Start �{�ԏ�Q#1398 �ŐV�̔z���悩��ڋq���擾�������B
            ,lr_mst_data_rec.customer_code              -- �ڋq
-- 2009/05/22 H.Itou Add End
      FROM   xxcmn_cust_accounts2_v          xcav       -- �ڋq���View2
            ,xxcmn_cust_acct_sites2_v        xcasv      -- �ڋq�T�C�g���View2
      WHERE  xcasv.party_id                   = xcav.party_id
      AND    xcav.start_date_active          <= lr_mst_data_rec.shipped_date
      AND    xcav.end_date_active            >= lr_mst_data_rec.shipped_date
      AND    xcasv.start_date_active         <= lr_mst_data_rec.shipped_date
      AND    xcasv.end_date_active           >= lr_mst_data_rec.shipped_date
      AND    xcasv.party_site_number          = lr_mst_data_rec.result_deliver_to
-- 2009/05/22 H.Itou Add Start �{�ԏ�Q#1398
      AND    xcav.account_status              = 'A'
      AND    xcasv.party_site_status          = 'A'
      AND    xcasv.cust_acct_site_status      = 'A'
-- 2009/05/22 H.Itou Add End
      AND    ROWNUM                           = 1;
--
     -- �ڋq�z����ւ̏o�ׂ̏ꍇ
     IF (mst_rec.customer_class_code = gv_cust_class_code_10) THEN
       -- �󒍃w�b�_�A�h�I������擾�����ڋq�R�[�h
       mst_rec.customer_code := lr_mst_data_rec.customer_code;
--
     -- �ڋq�z����ւ̏o�ׂłȂ��ꍇ
     ELSE
       -- �_�~�[�u000000000�v���Z�b�g
       mst_rec.customer_code := gv_dummy_cust_code;
     END IF;
-- 2008/09/18 1.17 Mod ��
      mst_rec.request_no        := lr_mst_data_rec.request_no;         -- �˗�No
      mst_rec.request_item_code := lr_mst_data_rec.request_item_code;  -- �˗��i��
      mst_rec.shipped_quantity  := lr_mst_data_rec.shipped_quantity;   -- �o�׎��ѐ���
      mst_rec.delete_flag       := lr_mst_data_rec.delete_flag;        -- �폜�t���O
      mst_rec.item_no           := lr_mst_data_rec.item_no;            -- �e�i��
-- 2008/12/24 v2.1 UPDATE START
--      mst_rec.new_crowd_code    := lr_mst_data_rec.new_crowd_code;     -- �V�E�Q�R�[�h
      mst_rec.crowd_code        := lr_mst_data_rec.crowd_code;         -- �Q�R�[�h
-- 2008/12/24 v2.1 UPDATE END
      mst_rec.num_of_cases      := lr_mst_data_rec.num_of_cases;       -- �P�[�X����
-- 2008/07/14 1.3 Update Start
--      mst_rec.prod_class_code   := lr_mst_data_rec.prod_class_code;    -- ���i�敪
      mst_rec.prod_class_h_code := lr_mst_data_rec.prod_class_h_code;  -- �{�Џ��i�敪
-- 2008/07/14 1.3 Update End
--
      mst_rec.order_line_id     := lr_mst_data_rec.order_line_id;      -- �󒍖��׃A�h�I��ID
--
      mst_rec.cases_values      := TO_NUMBER(mst_rec.num_of_cases);
--
      mst_rec.vd_arrival_date   := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYYMMDD');
--
      -- �e�[�u���̃��b�N
      tbl_lock(mst_rec,
               lv_errbuf,
               lv_retcode,
               lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      gt_master_tbl(ln_cnt) := mst_rec;
--
      gt_order_line_id(ln_cnt) := mst_rec.order_line_id;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_results_data;
--
  /***********************************************************************************
   * Procedure Name   : get_request_data
   * Description      : �o�׈˗����̎擾
   ***********************************************************************************/
  PROCEDURE get_request_data(
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_request_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_prof_name   CONSTANT VARCHAR2(100) := '�󒍃^�C�v';
--
    -- *** ���[�J���ϐ� ***
    ln_cnt                NUMBER;
    mst_rec               masters_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
-- 2008/09/04 Mod ��
/*
      SELECT xoha.deliver_from                       -- �o�׌�
*/
-- 2008/09/04 Mod ��
      SELECT /*+ leading(xola xoha) use_nl(xoha xola ximv.ximb ximv.iimb ) */ 
             xoha.deliver_from                       -- �o�׌�
            ,xoha.head_sales_branch                  -- �Ǌ����_
            ,xoha.order_type_id                      -- �󒍃^�C�vID
            ,DECODE(xoha.req_status,gv_req_status_03,NVL( xoha.schedule_arrival_date, xoha.arrival_date ),   -- ���ח\���
                                    gv_req_status_04,xoha.arrival_date,            -- ���ד�
                                    NULL
                   ) as arrival_date                 -- ���ד�
            ,DECODE(xoha.req_status,gv_req_status_03,NVL( xoha.deliver_to, xoha.result_deliver_to ),         -- �o�א�
                                    gv_req_status_04,xoha.result_deliver_to,       -- �o�א�_����
                                    NULL
                   ) as deliver_to                   -- �o�א�
            ,xoha.customer_code                      -- �ڋq
            ,xoha.request_no                         -- �˗�No
            ,xoha.cust_po_number                     -- �ڋq�����ԍ�
            ,DECODE(xoha.req_status,gv_req_status_03,NVL( xoha.schedule_ship_date, xoha.shipped_date ),     -- �o�ח\���
                                    gv_req_status_04,xoha.shipped_date,            -- �o�ד�
                                    NULL
                   ) as shipped_date                 -- �o�ד�
            ,xoha.arrival_time_from                  -- ���׎���From
            ,xola.order_line_id                      -- �󒍖��׃A�h�I��ID
            ,xola.request_item_code                  -- �˗��i��
            ,xola.quantity                           -- ����
            ,xola.delete_flag                        -- �폜�t���O
            ,ximv.num_of_cases                       -- �P�[�X����
-- 2008/07/14 1.3 Update Start
--            ,xic4.prod_class_code                -- ���i�敪
-- 2008/09/04 Mod ��
--            ,xicv2.prod_class_h_code             -- �{�Џ��i�敪
-- 2008/07/14 1.3 Update End
            ,(SELECT MAX(CASE
                        WHEN xicv.category_set_name = '�{�Џ��i�敪' THEN
                          mcb.segment1
                        ELSE
                          NULL
                     END) AS prod_class_h_code          -- �{�Џ��i�敪
              FROM    xxcmn_item_categories_v   xicv     -- OPM�i�ڃJ�e�S���������VIEW
                     ,mtl_categories_b          mcb
              WHERE   xicv.category_id  = mcb.category_id
              AND     xicv.structure_id = mcb.structure_id
              AND     xicv.item_id      = ximv.item_id
             ) prod_class_h_code
-- 2008/09/04 Mod ��
      FROM   xxwsh_order_headers_all       xoha          -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all         xola          -- �󒍖��׃A�h�I��
            ,xxwsh_oe_transaction_types2_v otta          -- �󒍃^�C�v���VIEW
            ,xxcmn_item_mst_v              ximv          -- OPM�i�ڏ��VIEW
-- 2008/09/04 Del ��
-- 2008/07/14 1.3 Update Start
--            ,xxcmn_item_categories4_v      xic4          -- OPM�i�ڃJ�e�S���������VIEW4
/*
            ,(SELECT  xicv.item_id
                     ,MAX(CASE
                        WHEN xicv.category_set_name = '�{�Џ��i�敪' THEN
                          mcb.segment1
                        ELSE
                          NULL
                      END) AS prod_class_h_code          -- �{�Џ��i�敪
            FROM      xxcmn_item_categories_v   xicv     -- OPM�i�ڃJ�e�S���������VIEW
                     ,mtl_categories_b          mcb
            WHERE     xicv.category_id  = mcb.category_id
            AND       xicv.structure_id = mcb.structure_id
            GROUP BY  xicv.item_id) xicv2
*/
-- 2008/07/14 1.3 Update End
-- 2008/09/04 Del ��
      WHERE  xoha.order_header_id       = xola.order_header_id
      AND    xoha.order_type_id         = otta.transaction_type_id
      AND    xola.request_item_code     = ximv.item_no
-- 2008/07/14 1.3 Update Start
--      AND    ximv.item_id               = xic4.item_id
-- 2008/09/04 Del ��
--      AND    ximv.item_id               = xicv2.item_id
-- 2008/09/04 Del ��
-- 2008/07/14 1.3 Update End
      AND    xoha.req_status           >= gv_req_status_03                --�u���ߍς݁v�ȏ�
      AND    xoha.req_status           <> gv_req_status_99                --�u����v�ȊO
      AND    NVL(xoha.latest_external_flag,gv_flag_off) = gv_flag_on      -- �ŐV�̂�
-- 2008/09/18 1.17 Mod �� T_TE080_BPO_400 �w�E79 �o�׈˗��ȊO�̏o�׃f�[�^�����o�ΏۂƂ���B
--      AND    otta.transaction_type_name = gv_tran_type_name               -- �o�׈˗�
      AND    otta.shipping_shikyu_class = gv_shipping_shikyu_class_1        -- �o�׎x���敪���u1�F�o�׈˗��v
-- 2008/09/18 1.17 Mod ��
      AND    otta.order_category_code   = gv_category_code                -- ��
      AND    NVL(otta.adjs_class,gv_adjs_class_req) <> gv_adjs_class_adj  -- �݌ɒ����ȊO
      AND    NVL(xola.delete_flag,gv_flag_off)      <> gv_flag_on         -- �폜�ȊO
      AND    NVL(xola.shipping_request_if_flg, gv_flag_off ) = gv_flag_off  -- �o�͍ς݈ȊO
      ORDER BY xoha.request_no,xola.request_item_code;
--
    -- *** ���[�J���E���R�[�h ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    ln_cnt := 1;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.deliver_from       := lr_mst_data_rec.deliver_from;        -- �o�׌�
      mst_rec.head_sales_branch  := lr_mst_data_rec.head_sales_branch;   -- �Ǌ����_
      mst_rec.order_type_id      := lr_mst_data_rec.order_type_id;       -- �󒍃^�C�vID
-- 2008/09/18 1.17 Mod �� T_S_630 �ڋq�敪�ɂ��ڋq�R�[�h������
--      mst_rec.customer_code      := lr_mst_data_rec.customer_code;       -- �ڋq
--
      -- �ڋq�敪�擾
      SELECT xcav.customer_class_code                   -- �ڋq�敪
-- 2009/05/22 H.Itou Add Start �{�ԏ�Q#1398
            ,xcav.party_number                          -- �ڋq
-- 2009/05/22 H.Itou Add End
      INTO   mst_rec.customer_class_code
-- 2009/05/22 H.Itou Add Start �{�ԏ�Q#1398 �ŐV�̔z���悩��ڋq���擾�������B
            ,lr_mst_data_rec.customer_code              -- �ڋq
-- 2009/05/22 H.Itou Add End
      FROM   xxcmn_cust_accounts2_v          xcav       -- �ڋq���View2
            ,xxcmn_cust_acct_sites2_v        xcasv      -- �ڋq�T�C�g���View2
      WHERE  xcasv.party_id                   = xcav.party_id
      AND    xcav.start_date_active          <= lr_mst_data_rec.shipped_date
      AND    xcav.end_date_active            >= lr_mst_data_rec.shipped_date
      AND    xcasv.start_date_active         <= lr_mst_data_rec.shipped_date
      AND    xcasv.end_date_active           >= lr_mst_data_rec.shipped_date
      AND    xcasv.party_site_number          = lr_mst_data_rec.deliver_to
-- 2009/05/22 H.Itou Add Start �{�ԏ�Q#1398
      AND    xcav.account_status              = 'A'
      AND    xcasv.party_site_status          = 'A'
      AND    xcasv.cust_acct_site_status      = 'A'
-- 2009/05/22 H.Itou Add End
      AND    ROWNUM                           = 1;
--
     -- �ڋq�z����ւ̏o�ׂ̏ꍇ
     IF (mst_rec.customer_class_code = gv_cust_class_code_10) THEN
       -- �󒍃w�b�_�A�h�I������擾�����ڋq�R�[�h
       mst_rec.customer_code := lr_mst_data_rec.customer_code;
--
     -- �ڋq�z����ւ̏o�ׂłȂ��ꍇ
     ELSE
       -- �_�~�[�u000000000�v���Z�b�g
       mst_rec.customer_code := gv_dummy_cust_code;
     END IF;
-- 2008/09/18 1.17 Mod ��
      mst_rec.request_no         := lr_mst_data_rec.request_no;          -- �˗�No
      mst_rec.cust_po_number     := lr_mst_data_rec.cust_po_number;      -- �ڋq�����ԍ�
      mst_rec.arrival_time_from  := lr_mst_data_rec.arrival_time_from;   -- ���׎���From
      mst_rec.request_item_code  := lr_mst_data_rec.request_item_code;   -- �˗��i��
      mst_rec.quantity           := lr_mst_data_rec.quantity;            -- ����
      mst_rec.delete_flag        := lr_mst_data_rec.delete_flag;         -- �폜�t���O
      mst_rec.num_of_cases       := lr_mst_data_rec.num_of_cases;        -- �P�[�X����
-- 2008/07/14 1.3 Update Start
--      mst_rec.prod_class_code    := lr_mst_data_rec.prod_class_code;     -- ���i�敪
      mst_rec.prod_class_h_code  := lr_mst_data_rec.prod_class_h_code;   -- �{�Џ��i�敪
-- 2008/07/14 1.3 Update End
--
      mst_rec.order_line_id      := lr_mst_data_rec.order_line_id;       -- �󒍖��׃A�h�I��ID
--
      mst_rec.arrival_date       := lr_mst_data_rec.arrival_date;        -- ���ח\���
      mst_rec.deliver_to         := lr_mst_data_rec.deliver_to;          -- �o�א�
      mst_rec.shipped_date       := lr_mst_data_rec.shipped_date;        -- �o�ח\���
--
      mst_rec.cases_values       := TO_NUMBER(mst_rec.num_of_cases);
--
      mst_rec.vd_arrival_date    := TO_CHAR(mst_rec.arrival_date,'YYYY/MM/DD');
      mst_rec.vd_shipped_date    := TO_CHAR(mst_rec.shipped_date,'YYYY/MM/DD');
      mst_rec.v_arrival_date     := TO_CHAR(mst_rec.arrival_date,'YYYYMMDD');
      mst_rec.v_shipped_date     := TO_CHAR(mst_rec.shipped_date,'YYYYMMDD');
--
      -- �e�[�u���̃��b�N
      tbl_lock(mst_rec,
               lv_errbuf,
               lv_retcode,
               lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �˗��敪�̎擾
      get_request_class(mst_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      -- �G���[
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- �x��
      ELSIF (lv_retcode = gv_status_warn) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_05,
                                              gv_type_name,
                                              lv_prof_name);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := gv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
--
-- 2008/09/18 1.17 Mod �� T_TE080_BPO_400 �w�E79
--      END IF;
      -- �o�׋敪���VIEW.�˗��敪�Əo�׋敪���VIEW.�ڋq�敪���擾���A����NULL�̏ꍇ(�r���o��,���o��)��CSV�o�͂��Ȃ��B
      ELSIF (lv_retcode = gv_status_skip) THEN
        NULL;
--
      -- ����̏ꍇ�̂�CSV�o��
      ELSE
-- 2008/09/18 1.17 Mod ��
        gt_master_tbl(ln_cnt) := mst_rec;
--
        gt_order_line_id(ln_cnt) := mst_rec.order_line_id;
--
        ln_cnt := ln_cnt + 1;
-- 2008/09/18 1.17 Add �� T_TE080_BPO_400 �w�E79
      END IF;
-- 2008/09/18 1.17 Add ��
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_request_data;
--
  /***********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N       (F-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_inf_div    IN            VARCHAR2,     -- 1.�C���^�t�F�[�X�Ώ�
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_tkn_name     CONSTANT VARCHAR2(100) := '�C���^�t�F�[�X�Ώ�';
    lv_lookup_code  CONSTANT VARCHAR2(50)  := 'XXWSH_401F_INTERFACE_SUBJECT';
--
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    IF (iv_inf_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_num_40f_01,
                                            gv_tkn_parameter,
                                            lv_tkn_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���݃`�F�b�N
    SELECT COUNT(xlv.lookup_type)
    INTO   ln_cnt
    FROM   xxcmn_lookup_values_v xlv
    WHERE  xlv.lookup_type = lv_lookup_code
    AND    xlv.lookup_code = iv_inf_div;
-- 2008/08/04 Mod ��
--    AND    ROWNUM      = 1;
-- 2008/08/04 Mod ��
--
    -- ���݂��Ȃ�
    IF (ln_cnt < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_num_40f_03);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- WHO�J�����̎擾
    gn_created_by             := FND_GLOBAL.USER_ID;           -- �쐬��
    gd_creation_date          := SYSDATE;                      -- �쐬��
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- �ŏI�X�V��
    gd_last_update_date       := SYSDATE;                      -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    gd_program_update_date    := SYSDATE;                      -- �v���O�����X�V��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END parameter_check;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : �v���t�@�C���擾         (F-2)
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_prof_name     VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- XXWSH:IF�t�@�C���o�͐�f�B���N�g��_�o�׈˗���񒊏o(�o�׈˗�)
    gv_request_path := FND_PROFILE.VALUE('XXWSH_OB_IF_DEST_PATH_REQUEST');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_request_path IS NULL) THEN
      lv_prof_name := 'XXWSH:IF�t�@�C���o�͐�f�B���N�g��_�o�׈˗���񒊏o(�o�׈˗�)';
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:IF�t�@�C����_�o�׈˗���񒊏o(�o�׈˗�)
    gv_request_file := FND_PROFILE.VALUE('XXWSH_OB_IF_FILENAME_REQUEST');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_request_file IS NULL) THEN
      lv_prof_name := 'XXWSH:IF�t�@�C����_�o�׈˗���񒊏o(�o�׈˗�)';
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:IF�t�@�C���o�͐�f�B���N�g��_�o�׈˗���񒊏o(�o�׎���)
    gv_results_path := FND_PROFILE.VALUE('XXWSH_OB_IF_DEST_PATH_RESULTS');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_results_path IS NULL) THEN
      lv_prof_name := 'XXWSH:IF�t�@�C���o�͐�f�B���N�g��_�o�׈˗���񒊏o(�o�׎���)';
      RAISE get_profile_expt;
    END IF;
--
    -- XXWSH:IF�t�@�C����_�o�׈˗���񒊏o(�o�׎���)
    gv_results_file := FND_PROFILE.VALUE('XXWSH_OB_IF_FILENAME_RESULTS');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_results_file IS NULL) THEN
      lv_prof_name := 'XXWSH:IF�t�@�C����_�o�׈˗���񒊏o(�o�׎���)';
      RAISE get_profile_expt;
    END IF;
--
  EXCEPTION
    WHEN get_profile_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_num_40f_04,
                                            gv_tkn_prof_name,
                                            lv_prof_name);
--
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||ov_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_profile;
--
  /***********************************************************************************
   * Procedure Name   : get_obj_data
   * Description      : �o�׈˗���񒊏o         (F-3)
   ***********************************************************************************/
  PROCEDURE get_obj_data(
    iv_inf_div    IN            VARCHAR2,     -- 1.�C���^�t�F�[�X�Ώ�
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_obj_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    IF (iv_inf_div = gv_inf_sub_request) THEN
--
      -- �o�׈˗����̎擾
      get_request_data(lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
    ELSE
--
      -- �o�׎��я��̎擾
      get_results_data(lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- �Ώی����Ȃ�
    IF (gt_master_tbl.COUNT < 1) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_02);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- 2008/08/04 Mod ��
--        gn_warn_cnt := gn_warn_cnt + 1;
-- 2008/08/04 Mod ��
        ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_obj_data;
--
  /***********************************************************************************
   * Procedure Name   : put_obj_data
   * Description      : �o�׈˗����o��         (F-4)
   ***********************************************************************************/
  PROCEDURE put_obj_data(
    iv_inf_div    IN            VARCHAR2,     -- 1.�C���^�t�F�[�X�Ώ�
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_obj_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
-- 2008/08/22 Add ��
    cv_def_date     CONSTANT VARCHAR2(4)  := '9999';
    cv_def_kbn      CONSTANT VARCHAR2(1)  := '1';
-- 2008/08/22 Add ��
--
    -- *** ���[�J���ϐ� ***
    mst_rec         masters_rec;
    lv_data         VARCHAR2(5000);
    lf_file_hand    UTL_FILE.FILE_TYPE;         -- �t�@�C���E�n���h���̐錾
    lv_dir          VARCHAR2(2000);             -- �o�͐�
    lv_file         VARCHAR2(2000);             -- �t�@�C����
--
    ln_retcd        NUMBER;
    lv_outno        VARCHAR2(12);
    ln_qty          NUMBER;
    ln_len          NUMBER;
    lv_str          VARCHAR2(20);
-- 2008/08/22 Add ��
    lv_def_date     VARCHAR2(6);
-- 2008/08/22 Add ��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �o�׈˗�
    IF (iv_inf_div = gv_inf_sub_request) THEN
      lv_dir  := gv_request_path;
      lv_file := gv_request_file;
--
    -- �o�׎���
    ELSE
      lv_dir  := gv_results_path;
      lv_file := gv_results_file;
    END IF;
--
    gn_target_cnt := gt_master_tbl.COUNT;
--
    BEGIN
--
      -- �t�@�C���I�[�v��
      lf_file_hand := UTL_FILE.FOPEN(lv_dir,
                                     lv_file,
                                     'w');
--
      -- �f�[�^����
      IF (gt_master_tbl.COUNT > 0) THEN
--
        <<file_put_loop>>
        FOR i IN 1..gt_master_tbl.COUNT LOOP
          mst_rec := gt_master_tbl(i);
--
          -- �˗�No�R���o�[�g�֐�
          ln_retcd := xxwsh_common_pkg.convert_request_number(
                              iv_conv_div             => '2'
                             ,iv_pre_conv_request_no  => mst_rec.request_no
                             ,ov_aft_conv_request_no  => lv_outno
                             );
--
          -- �R���o�[�g�G���[
          IF (ln_retcd <> 0) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_tkn_num_40f_06);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ���ʕ���
          lv_data := gv_data_div||cv_sep_com||gv_r_no||cv_sep_com||gv_continue;
--
          -- �o�׈˗�
          IF (iv_inf_div = gv_inf_sub_request) THEN
-- 2008/08/22 Add ��
            lv_def_date := cv_def_date || mst_rec.prod_class_h_code
                                       || mst_rec.request_class;
-- 2008/08/22 Add ��
--
-- 2008/08/22 Mod ��
--            lv_data := lv_data || cv_sep_com || gv_max_date;                -- �v��N��
            lv_data := lv_data || cv_sep_com || lv_def_date;                -- �v��N��
-- 2008/08/22 Mod ��
            lv_data := lv_data || cv_sep_com || mst_rec.deliver_from;       -- �o�ɋ��_�R�[�h
            lv_data := lv_data || cv_sep_com || mst_rec.head_sales_branch;  -- �˗����_�R�[�h
-- 2008/07/14 1.3 Update Start
--            lv_data := lv_data || cv_sep_com || mst_rec.prod_class_code;    -- ���i�敪
--            lv_data := lv_data || cv_sep_com || mst_rec.prod_class_h_code;  -- �{�Џ��i�敪
-- 2008/07/14 1.3 Update End
--            lv_data := lv_data || cv_sep_com || mst_rec.request_class;      -- �˗��敪
-- 2008/08/22 Mod ��
--            lv_data := lv_data || cv_sep_com || cv_def_kbn;                 -- �{�Џ��i�敪
--            lv_data := lv_data || cv_sep_com || cv_def_kbn;                 -- �˗��敪
-- 2008/08/22 Mod ��
-- 2008/12/03 Mod 2.0 Update Start �o�׎��тƓ��l�̎d�g�݂Ƃ���B�{��#255
            -- �`�[�敪1
            IF (SUBSTR(mst_rec.head_sales_branch,1,1) = '7') THEN
              lv_data := lv_data || cv_sep_com || '2';              -- ���X
            ELSE
              lv_data := lv_data || cv_sep_com || '1';              -- ���_�o��
            END IF;
            lv_data := lv_data || cv_sep_com || '1';                        -- �`�[�敪2
-- 2008/12/03 Mod 2.0 Update End
            lv_data := lv_data || cv_sep_com || mst_rec.v_arrival_date;     -- ����(YYYYMMDD)
            lv_data := lv_data || cv_sep_com || mst_rec.deliver_to;         -- �z����R�[�h
            lv_data := lv_data || cv_sep_com || mst_rec.customer_code;      -- �ڋq�R�[�h
            lv_data := lv_data || cv_sep_com || lv_outno;                   -- �˗��`�[NO
--
            -- �i���R�[�h
            ln_len := LENGTHB(mst_rec.request_item_code);
            IF (ln_len > 6) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.request_item_code,ln_len,5);
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.request_item_code;
            END IF;
--
            lv_data := lv_data || cv_sep_com || gv_num_zero;                -- �\��1
            lv_data := lv_data || cv_sep_com || gv_num_zero;                -- �\��2
--
            --�P�[�X��
            IF ((mst_rec.num_of_cases IS NULL)
              OR (mst_rec.num_of_cases = gv_num_zero)
              OR (mst_rec.quantity IS NULL)) THEN
              lv_str := NULL;
            ELSE
              ln_qty := TRUNC(mst_rec.quantity / mst_rec.cases_values);
              lv_str := TO_CHAR(ln_qty,'FM999999');
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            --����
            IF (mst_rec.num_of_cases IS NULL) THEN
              lv_data := lv_data || cv_sep_com || NULL;
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.num_of_cases;
            END IF;
--
            --�{��(�o��)
            IF ((mst_rec.num_of_cases IS NULL)
              OR (mst_rec.num_of_cases = gv_num_zero)) THEN
              lv_str := TO_CHAR(mst_rec.quantity);
            ELSE
              IF (mst_rec.quantity IS NULL) THEN
                lv_str := NULL;
              ELSE
                ln_qty  := MOD(mst_rec.quantity, mst_rec.cases_values);
                lv_str  := TO_CHAR(ln_qty,'FM999999990.99');
              END IF;
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            --PO#
            ln_len := LENGTHB(mst_rec.cust_po_number);
            IF (ln_len > 9) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.cust_po_number,ln_len,9);
            ELSE
-- 2008/11/06 1.17 Mod �� 9�������͍�0���߂��s��9���ɂ���B
--              lv_data := lv_data || cv_sep_com || mst_rec.cust_po_number;
              lv_data := lv_data || cv_sep_com || LPAD(mst_rec.cust_po_number, 9, '0');
-- 2008/11/06 1.17 Mod ��
            END IF;
--
            lv_data := lv_data || cv_sep_com || mst_rec.v_shipped_date;     -- ������(YYYYMMDD)
            lv_data := lv_data || cv_sep_com || mst_rec.arrival_time_from;  -- ���Ԏw��
            lv_data := lv_data || cv_sep_com || NULL;                       -- �\��4
--
          -- �o�׎���
          ELSE
            lv_data := lv_data || cv_sep_com || TO_CHAR(mst_rec.arrival_date,'YYYYMM');
--
            -- ���͋��_�R�[�h
-- 2008/07/14 1.3 Update Start
--            IF (mst_rec.prod_class_code = gv_prod_class_reef) THEN
            IF (mst_rec.prod_class_h_code = gv_prod_class_reef) THEN
-- 2008/07/14 1.3 Update End
              lv_data := lv_data || cv_sep_com || gv_base_code_reef;
            ELSE
              lv_data := lv_data || cv_sep_com || gv_base_code_drink;
            END IF;
--
            lv_data := lv_data || cv_sep_com || mst_rec.head_sales_branch;  -- ���苒�_�R�[�h
--
            -- �`�[�敪1
            IF (SUBSTR(mst_rec.head_sales_branch,1,1) = '7') THEN
              lv_data := lv_data || cv_sep_com || '2';              -- ���X
            ELSE
              lv_data := lv_data || cv_sep_com || '1';              -- ���_�o��
            END IF;
--
            lv_data := lv_data || cv_sep_com || '1';                        -- �`�[�敪2
            lv_data := lv_data || cv_sep_com || mst_rec.v_arrival_date;     -- ���ד�(YYYYMMDD)
            lv_data := lv_data || cv_sep_com || mst_rec.deliver_to;         -- �z����R�[�h
            lv_data := lv_data || cv_sep_com || mst_rec.customer_code;      -- �ڋq�R�[�h
            lv_data := lv_data || cv_sep_com || lv_outno;                   -- �`�[NO
--
            -- �i���R�[�h�E�G���g���[
            ln_len := LENGTHB(mst_rec.request_item_code);
            IF (ln_len > 6) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.request_item_code,ln_len,5);
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.request_item_code;
            END IF;
--
             -- �i���R�[�h�E�e
            ln_len := LENGTHB(mst_rec.item_no);
            IF (ln_len > 6) THEN
              lv_data := lv_data || cv_sep_com || cutoff_str(mst_rec.item_no,ln_len,5);
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.item_no;
            END IF;
--
-- 2008/12/24 v2.1 UPDATE START
--            lv_data := lv_data || cv_sep_com || mst_rec.new_crowd_code;     -- �Q�R�[�h
            lv_data := lv_data || cv_sep_com || mst_rec.crowd_code;         -- �Q�R�[�h
-- 2008/12/24 v2.1 UPDATE END
--
            -- �P�[�X��
            IF (NVL(mst_rec.delete_flag,gv_flag_off) = gv_flag_on) THEN
              lv_str := gv_num_zero;
            ELSE
              IF ((mst_rec.num_of_cases IS NULL)
                OR (mst_rec.num_of_cases = gv_num_zero)
                OR (mst_rec.shipped_quantity IS NULL)) THEN
                lv_str := NULL;
              ELSE
                ln_qty := TRUNC(mst_rec.shipped_quantity / mst_rec.cases_values);
                lv_str := TO_CHAR(ln_qty,'FM999999');
              END IF;
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            -- ����
            IF (mst_rec.num_of_cases IS NULL) THEN
              lv_data := lv_data || cv_sep_com || NULL;
            ELSE
              lv_data := lv_data || cv_sep_com || mst_rec.num_of_cases;
            END IF;
--
            -- �{��(�o��)
            IF (NVL(mst_rec.delete_flag,gv_flag_off) = gv_flag_on) THEN
              lv_str := gv_num_zero;
            ELSE
              IF ((mst_rec.num_of_cases IS NULL)
                OR (mst_rec.num_of_cases = gv_num_zero)) THEN
                lv_str := TO_CHAR(mst_rec.shipped_quantity);
              ELSE
                IF (mst_rec.shipped_quantity IS NULL) THEN
                  lv_str := NULL;
                ELSE
                  ln_qty  := MOD(mst_rec.shipped_quantity, mst_rec.cases_values);
                  lv_str  := TO_CHAR(ln_qty,'FM999999990.99');
                END IF;
              END IF;
            END IF;
            lv_data := lv_data || cv_sep_com || lv_str;
--
            -- �\��
            lv_data := lv_data || cv_sep_com || NULL;                -- �\��1
            lv_data := lv_data || cv_sep_com || NULL;                -- �\��2
            lv_data := lv_data || cv_sep_com || NULL;                -- �\��3
            lv_data := lv_data || cv_sep_com || NULL;                -- �\��4
          END IF;
--
          -- �f�[�^�o��
          UTL_FILE.PUT_LINE(lf_file_hand,lv_data);
        END LOOP file_put_loop;
      END IF;
--
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
--
      WHEN UTL_FILE.INVALID_PATH OR         -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_FILENAME OR     -- �t�@�C�����s���G���[
           UTL_FILE.ACCESS_DENIED OR        -- �t�@�C���A�N�Z�X�����G���[
           UTL_FILE.WRITE_ERROR THEN        -- �������݃G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_num_40f_07);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END put_obj_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_inf_div    IN            VARCHAR2,     -- 1.�C���^�t�F�[�X�Ώ�
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- 2008/12/24 v2.1 ADD START
    -- �Q�R�[�h�K�p���t
    gv_sysdate    := TO_CHAR(SYSDATE, 'YYYY/MM/DD');
--
-- 2008/12/24 v2.1 ADD END
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      �p�����[�^�`�F�b�N(F-1)          ***
    --*********************************************
    parameter_check(
           iv_inf_div,   -- �C���^�t�F�[�X�Ώ�
           lv_errbuf,    -- �G���[�E���b�Z�[�W
           lv_retcode,   -- ���^�[���E�R�[�h
           lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      �v���t�@�C���擾(F-2)            ***
    --*********************************************
    get_profile(
           lv_errbuf,    -- �G���[�E���b�Z�[�W
           lv_retcode,   -- ���^�[���E�R�[�h
           lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      �o�׈˗���񒊏o(F-3)            ***
    --*********************************************
    get_obj_data(
           iv_inf_div,   -- �C���^�t�F�[�X�Ώ�
           lv_errbuf,    -- �G���[�E���b�Z�[�W
           lv_retcode,   -- ���^�[���E�R�[�h
           lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �x��
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    --*********************************************
    --***      �o�׈˗����o��(F-4)            ***
    --*********************************************
    put_obj_data(
           iv_inf_div,   -- �C���^�t�F�[�X�Ώ�
           lv_errbuf,    -- �G���[�E���b�Z�[�W
           lv_retcode,   -- ���^�[���E�R�[�h
           lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- I/F�σt���O�̍X�V
    if_flg_upd(
           iv_inf_div,   -- �C���^�t�F�[�X�Ώ�
           lv_errbuf,    -- �G���[�E���b�Z�[�W
           lv_retcode,   -- ���^�[���E�R�[�h
           lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_inf_div    IN            VARCHAR2       -- 1.�C���^�t�F�[�X�Ώ�
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
--
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
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
      iv_inf_div,  -- 1.�C���^�t�F�[�X�Ώ�
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
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh400005c;
/
