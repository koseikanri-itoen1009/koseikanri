CREATE OR REPLACE PACKAGE BODY xxwsh400010c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400010c(body)
 * Description      : �o�׈˗����߉�������
 * MD.050           : �o�׈˗� T_MD050_BPO_401
 * MD.070           : �o�׈˗����߉�������  T_MD070_BPO_40K
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  ins_xxwsh_tightening_control
 *                         �������R�[�h�o�^�v���V�[�W��
 *  check_tightening_status2 ���߃X�e�[�^�X�`�F�b�N(������������p)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/04    1.0  Oracle �㌴���D   ����쐬
 *  2008/5/19     1.1  Oracle �㌴���D   �����ύX�v��#80�Ή� �p�����[�^�u���_�v�ǉ�
 *  2008/07/04    1.2  Oracle �k�������v ST#366�Ή� ���������̋��_�A���_�J�e�S����ALL�̍ۂ�
 *                                       ���������ʊ֐��̏����ƈقȂ邽�ߋ��ʊ֐�����R�s�[��
 *                                       ����
 *  2009/01/20    1.3  Oracle �ɓ��ЂƂ� �{�ԏ�Q#1053�Ή�
 *  2009/01/27    1.4  Oracle �㌴���D   �{�ԏ�Q#1089�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0'; -- ����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1'; -- �x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2'; -- �G���[
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C'; -- �X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G'; -- �X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E'; -- �X�e�[�^�X(�G���[)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwsh400010c';
                                                                 -- �p�b�P�[�W��
  gv_xxwsh                    CONSTANT VARCHAR2(100) := 'XXWSH';
                                                                 -- �A�v���P�[�V�����Z�k��
  gv_line_feed                CONSTANT VARCHAR2(1)   := CHR(10);
                                                                 -- ���s�R�[�h
  gv_xxwsh_release_class      CONSTANT VARCHAR2(100) := '2';
                                                                 -- �����i����/�����敪�j
  gv_tighten_status_1         CONSTANT VARCHAR2(100) := '1';
                                                                 -- ���߃X�e�[�^�X 1:���ߏ��������{
  gv_tighten_status_3         CONSTANT VARCHAR2(100) := '3';
                                                                 -- ���߃X�e�[�^�X 3:���߉���
  gv_dummy_order_type_id      CONSTANT VARCHAR2(100) := '-999';
                                                                 -- �_�~�[�󒍃^�C�vID
  gv_all                      CONSTANT VARCHAR2(100) := 'ALL';
                                                                 -- �uALL�v
  gv_output_msg               CONSTANT VARCHAR2(100) := 'APP-XXWSH-01701';
                                                                 -- �o�͌���
  gv_mst_format_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11451';
                                                                 -- �}�X�^�����G���[���b�Z�[�W
  gv_tightening_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11452';
                                                                 -- ���ߏ������{�G���[
  gv_released_err             CONSTANT VARCHAR2(100) := 'APP-XXWSH-11453';
                                                                 -- ���߉������{�ς݃G���[
  gv_need_param_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11454';
                                                        -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
  gv_suitable_err             CONSTANT VARCHAR2(100) := 'APP-XXWSH-11455';
                                                                 -- �Ó����`�F�b�N
  gv_alternative_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11456';
                                                                 -- ������͍��ڃG���[���b�Z�[�W
  gv_cnst_tkn_para            CONSTANT VARCHAR2(100) := 'PARAMETER';
                                                                 -- ���̓p�����[�^��
  gv_cnst_tkn_date            CONSTANT VARCHAR2(100) := 'DATE';
                                                                 -- �o�ɓ�
  gv_tkn_sales_branch_category CONSTANT VARCHAR2(100) := '���_�v����сu���_�J�e�S��';
                                                                 -- �g�[�N���u���_����ы��_�J�e�S���v
  gv_tkn_lead_time_day        CONSTANT VARCHAR2(100) := '���Y����LT/����ύXLT';
                                                                 -- �g�[�N���u���Y����LT/����ύXLT�v
  gv_tkn_schedule_ship_date   CONSTANT VARCHAR2(100) := '�o�ɓ�';
                                                                 -- �g�[�N���u�o�ɓ��v
  gv_tkn_base_record_class    CONSTANT VARCHAR2(100) := '����R�[�h�敪';
                                                                 -- �g�[�N���u����R�[�h�敪�v
  gv_tkn_prod_class           CONSTANT VARCHAR2(100) := '���i�敪';
                                                                 -- �g�[�N���u���i�敪�v
  gv_tkn_transaction_type_id CONSTANT VARCHAR2(100) := '�o�Ɍ`��';
                                                                 -- �g�[�N���u�o�Ɍ`�ԁv
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- WHO�J����
  gt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- �쐬�ҁA�ŏI�X�V��
  gt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- �ŏI�X�V���O�C��
  gt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- �v��ID
  gt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- �A�v���P�[�V����ID
  gt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- �v���O����ID
--
  -- �o�׈˗����ߊǗ���񒊏o�p
  gt_order_type_id           XXWSH_TIGHTENING_CONTROL.ORDER_TYPE_ID%TYPE;         -- �󒍃^�C�vID
  gt_deliver_from            XXWSH_TIGHTENING_CONTROL.DELIVER_FROM%TYPE;          -- �o�׌��ۊǏꏊ
  gt_prod_class_type         XXWSH_TIGHTENING_CONTROL.PROD_CLASS%TYPE;            -- ���i�敪
  gt_sales_branch            XXWSH_TIGHTENING_CONTROL.SALES_BRANCH%TYPE; -- ���_
  gt_sales_branch_category   XXWSH_TIGHTENING_CONTROL.SALES_BRANCH_CATEGORY%TYPE; -- ���_�J�e�S��
  gt_lead_time_day           XXWSH_TIGHTENING_CONTROL.LEAD_TIME_DAY%TYPE;         -- ���Y����LT/����ύXLT
  gt_schedule_ship_date      XXWSH_TIGHTENING_CONTROL.SCHEDULE_SHIP_DATE%TYPE;    -- �o�ח\���
  gt_tighten_release_class   XXWSH_TIGHTENING_CONTROL.TIGHTEN_RELEASE_CLASS%TYPE; -- ���߁^�����敪
  gt_base_record_class       XXWSH_TIGHTENING_CONTROL.BASE_RECORD_CLASS%TYPE;     -- ����R�[�h�敪
  gt_system_date             DATE;                                                -- �V�X�e�����t
--
  /**********************************************************************************
   * Procedure Name   : ins_xxwsh_tightening_control
   * Description      : �������R�[�h�̓o�^(K-3)
   ***********************************************************************************/
  PROCEDURE ins_xxwsh_tightening_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxwsh_tightening_control'; -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    --�o�׈˗����ߊǗ��A�h�I���e�[�u���ւ̓o�^
    INSERT INTO xxwsh_tightening_control
       (transaction_id            -- �g�����U�N�V����id
        ,concurrent_id            -- �R���J�����gid
        ,order_type_id            -- �󒍃^�C�vid
        ,deliver_from             -- �o�׌��ۊǏꏊ
        ,prod_class               -- ���i�敪
        ,sales_branch             -- ���_
        ,sales_branch_category    -- ���_�J�e�S��
        ,lead_time_day            -- ���Y����lt/����ύXlt
        ,schedule_ship_date       -- �o�ח\���
        ,tighten_release_class    -- ���߁^�����敪
        ,tightening_date          -- ���ߎ��{����
        ,base_record_class        -- ����R�[�h�敪
        ,created_by               -- �쐬��
        ,creation_date            -- �쐬��
        ,last_updated_by          -- �ŏI�X�V��
        ,last_update_date         -- �ŏI�X�V��
        ,last_update_login        -- �ŏI�X�V���O�C��
        ,request_id               -- �v��id
        ,program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����id
        ,program_id               -- �R���J�����g�E�v���O����id
        ,program_update_date      -- �v���O�����X�V��
       )
       VALUES
       (xxwsh_tightening_control_s1.NEXTVAL  -- �g�����U�N�V����ID
        ,gt_conc_request_id                  -- �R���J�����gID
        ,gt_order_type_id                    -- �󒍃^�C�vID
        ,gt_deliver_from                     -- �o�׌��ۊǏꏊ
        ,gt_prod_class_type                  -- ���i�敪
        ,gt_sales_branch                     -- ���_
        ,gt_sales_branch_category            -- ���_�J�e�S��
        ,gt_lead_time_day                    -- ���Y����LT/����ύXLT
        ,gt_schedule_ship_date               -- �o�ח\���
        ,gt_tighten_release_class            -- ���߁^�����敪
        ,gt_system_date                      -- ���ߎ��{����
        ,gt_base_record_class                -- ����R�[�h�敪
        ,gt_user_id                          -- �쐬��
        ,gt_system_date                      -- �쐬��
        ,gt_user_id                          -- �ŏI�X�V��
        ,gt_system_date                      -- �ŏI�X�V��
        ,gt_login_id                         -- �ŏI�X�V���O�C��
        ,gt_conc_request_id                  -- �v��ID
        ,gt_prog_appl_id                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,gt_conc_program_id                  -- �R���J�����g�E�v���O����ID
        ,gt_system_date                      -- �v���O�����X�V��
       );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_xxwsh_tightening_control;
-- Ver1.2 M.Hokkanji Start
-- ���_ALL�A���_�J�e�S��0(ALL)�̏ꍇ�̏��������ʊ֐��ƕύX���邽�ߒ��߃X�e�[�^�X�`�F�b�N�֐����R�s�[
--
  /**********************************************************************************
   * Function Name    : check_tightening_status2
   * Description      : ���߃X�e�[�^�X�`�F�b�N�֐�(������������p)
   ***********************************************************************************/
  FUNCTION check_tightening_status2(
    -- 1.�󒍃^�C�vID
    in_order_type_id          IN  xxwsh_tightening_control.order_type_id%TYPE,
    -- 2.�o�׌��ۊǏꏊ
    iv_deliver_from           IN  xxwsh_tightening_control.deliver_from%TYPE,
    -- 3.���_
    iv_sales_branch           IN  xxwsh_tightening_control.sales_branch%TYPE,
    -- 4.���_�J�e�S��
    iv_sales_branch_category  IN  xxwsh_tightening_control.sales_branch_category%TYPE,
    -- 5.���Y����LT
    in_lead_time_day          IN  xxwsh_tightening_control.lead_time_day%TYPE,
    -- 6.�o�ɓ�
    id_ship_date              IN  xxwsh_tightening_control.schedule_ship_date%TYPE,
    -- 7.���i�敪
    iv_prod_class             IN  xxwsh_tightening_control.prod_class%TYPE)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'check_tightening_status2'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_all                CONSTANT NUMBER        := -999;                      -- ALL(���l����)
    cv_all                CONSTANT VARCHAR2(3)   := 'ALL';                     -- ALL(��������)
    cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                       -- YES
    cv_no                 CONSTANT VARCHAR2(1)   := 'N';                       -- NO
    cv_close              CONSTANT VARCHAR2(1)   := '1';                       -- ����
    cv_cancel             CONSTANT VARCHAR2(1)   := '2';                       -- ����
    cv_inside_err         CONSTANT VARCHAR2(2)   := '-1';                      -- �����G���[
    cv_close_proc_n_enfo  CONSTANT VARCHAR2(1)   := '1';                       -- ���ߏ��������{
    cv_first_close_fin    CONSTANT VARCHAR2(1)   := '2';                       -- ������ߍ�
    cv_close_cancel       CONSTANT VARCHAR2(1)   := '3';                       -- ���߉���
    cv_re_close_fin       CONSTANT VARCHAR2(1)   := '4';                       -- �Ē��ߍ�
    cv_customer_class_code_1 CONSTANT VARCHAR2(1)   := '1';                    -- �ڋq�敪�F1
    cv_prod_class_1       CONSTANT VARCHAR2(1)   := '1';                       -- ���i�敪�F1
    cv_prod_class_2       CONSTANT VARCHAR2(1)   := '2';                       -- ���i�敪�F2
    cv_sales_branch_category_0 CONSTANT VARCHAR2(1)   := '0';                  -- ���_�J�e�S���F0
--
    -- *** ���[�J���ϐ� ***
    ln_count                  NUMBER;            -- �J�E���g����
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
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    BEGIN
      -- ���߉�����ԃ`�F�b�N
      -- �p�����[�^�u���_�v�����͂��ꂽ�ꍇ
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- �u���_�v����сA�u���_�v�ɕR�t���u���_�J�e�S���v�ŉ������R�[�h������      
-- Ver1.3 H.Itou Mod Start ���ߊǗ��e�[�u���̋��_��ALL�̏ꍇ�͌ڋq�}�X�^���������Ȃ�
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_cancel
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- ���_��ALL�łȂ��ꍇ(�ڋq�}�X�^������)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- ���_��ALL�̏ꍇ
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.4 M.Uehara Add start
                AND     (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                        FROM xxcmn_cust_accounts2_v    xcav
                                                       WHERE xcav.party_number         =  iv_sales_branch
                                                         AND     xcav.start_date_active    <= id_ship_date
                                                         AND     xcav.end_date_active      >= id_ship_date)
                         OR xtc.sales_branch_category = cv_all)
-- Ver1.3 M.Uehara Add End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- ���v����f�[�^������΢���߉������Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
--
      -- �p�����[�^�u���_�J�e�S���v�����͂��ꂽ�ꍇ
      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
        -- �u���_�J�e�S���v����сA�u���_�J�e�S���v�ɕR�t���S�Ắu���_�v�ŉ������R�[�h������
-- Ver1.3 H.Itou Mod Start ���ߊǗ��e�[�u���̋��_��ALL�̏ꍇ�͌ڋq�}�X�^���������Ȃ�
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_cancel
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- ���_��ALL�łȂ��ꍇ(�ڋq�}�X�^������)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- ���_��ALL�̏ꍇ
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- ���v����f�[�^��1���ł�����΢���߉������Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
--
      -- �p�����[�^�u���_�v����сu���_�J�e�S���v��'ALL'�̏ꍇ
      ELSIF ((NVL(iv_sales_branch,cv_all) = cv_all) AND (NVL(iv_sales_branch_category,cv_all) = cv_all)) THEN
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
-- Ver1.4 M.Uehara Del start
--        AND     xtc.sales_branch          =  cv_all
--        AND     xtc.sales_branch_category =  cv_all
-- Ver1.4 M.Uehara Del end
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_cancel;
--
        -- ���v����f�[�^��1���ł�����΢���߉������Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
      END IF;
--
      -- �Ē��ߏ�ԃ`�F�b�N
      -- �p�����[�^�u���_�v�����͂��ꂽ�ꍇ
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- �u���_�v����сA�u���_�v�ɕR�t���u���_�J�e�S���v�ŉ������R�[�h������
-- Ver1.3 H.Itou Mod Start ���ߊǗ��e�[�u���̋��_��ALL�̏ꍇ�͌ڋq�}�X�^���������Ȃ�
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- ���_��ALL�łȂ��ꍇ(�ڋq�}�X�^������)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          = iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- ���_��ALL�̏ꍇ
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.4 M.Uehara Add start
                AND     (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                        FROM xxcmn_cust_accounts2_v    xcav
                                                       WHERE xcav.party_number         =  iv_sales_branch
                                                         AND     xcav.start_date_active    <= id_ship_date
                                                         AND     xcav.end_date_active      >= id_ship_date)
                         OR xtc.sales_branch_category = cv_all)
-- Ver1.3 M.Uehara Add End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- ���v����f�[�^������΢�Ē��ߍςݣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
--
      -- �p�����[�^�u���_�J�e�S���v�����͂��ꂽ�ꍇ
      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
        -- �u���_�J�e�S���v����сA�u���_�J�e�S���v�ɕR�t���S�Ắu���_�v�ŉ������R�[�h������
-- Ver1.3 H.Itou Mod Start ���ߊǗ��e�[�u���̋��_��ALL�̏ꍇ�͌ڋq�}�X�^���������Ȃ�
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- ���_��ALL�łȂ��ꍇ(�ڋq�}�X�^������)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- ���_��ALL�̏ꍇ
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- ���v����f�[�^��1���ł�����΢�Ē��ߍςݣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
--
      -- �p�����[�^�u���_�v����сu���_�J�e�S���v��'ALL'�̏ꍇ
      ELSIF ((NVL(iv_sales_branch,cv_all) = cv_all) AND (NVL(iv_sales_branch_category,cv_all) = cv_all)) THEN
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch          =  cv_all
        AND     xtc.sales_branch_category =  cv_all
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_close;
--
        -- ���v����f�[�^��1���ł�����΢�Ē��ߍςݣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
      END IF;
--
      -- ������ߏ�ԃ`�F�b�N
      -- �p�����[�^�u���_�v�����͂��ꂽ�ꍇ
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- �u���_�v����сA�u���_�v�ɕR�t���u���_�J�e�S���v�ŉ������R�[�h������
-- Ver1.3 H.Itou Mod Start ���ߊǗ��e�[�u���̋��_��ALL�̏ꍇ�͌ڋq�}�X�^���������Ȃ�
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_yes
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- ���_��ALL�łȂ��ꍇ(�ڋq�}�X�^������)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- ���_��ALL�̏ꍇ
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.4 M.Uehara Add start
                AND     (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                        FROM xxcmn_cust_accounts2_v    xcav
                                                       WHERE xcav.party_number         =  iv_sales_branch
                                                         AND     xcav.start_date_active    <= id_ship_date
                                                         AND     xcav.end_date_active      >= id_ship_date)
                         OR xtc.sales_branch_category = cv_all)
-- Ver1.3 M.Uehara Add End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- ���v����f�[�^������΢������ߍϣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
--
      -- �p�����[�^�u���_�J�e�S���v�����͂��ꂽ�ꍇ
      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
        -- �u���_�J�e�S���v����сA�u���_�J�e�S���v�ɕR�t���S�Ắu���_�v�ŉ������R�[�h������
-- Ver1.3 H.Itou Mod Start ���ߊǗ��e�[�u���̋��_��ALL�̏ꍇ�͌ڋq�}�X�^���������Ȃ�
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_yes
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- ���_��ALL�łȂ��ꍇ(�ڋq�}�X�^������)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- ���_��ALL�̏ꍇ
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- ���v����f�[�^��1���ł�����΢������ߍϣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
--
      -- �p�����[�^�u���_�v����сu���_�J�e�S���v��'ALL'�̏ꍇ
      ELSIF ((NVL(iv_sales_branch,cv_all) = cv_all) AND (NVL(iv_sales_branch_category,cv_all) = cv_all)) THEN
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch          =  cv_all
        AND     xtc.sales_branch_category =  cv_all
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_yes
        AND     xtc.tighten_release_class =  cv_close;
--
        -- ���v����f�[�^��1���ł�����΢������ߍϣ��Ԃ�
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
      END IF;
--
      -- ���v����f�[�^���Ȃ��ꍇ�͢���ߏ��������{���Ԃ�
      RETURN cv_close_proc_n_enfo;
--
    EXCEPTION
      -- ���̑��̗�O���ɂ͢�����G���[���Ԃ�
      WHEN OTHERS THEN
        RETURN cv_inside_err;
    END;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_tightening_status2;
-- Ver1.2 M.Hokkanji End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_transaction_type_id    IN VARCHAR2,     --   �o�Ɍ`��
    iv_shipped_locat_code     IN VARCHAR2,     --   �o�Ɍ�
    iv_sales_branch           IN VARCHAR2,     --   ���_
    iv_sales_branch_category  IN VARCHAR2,     --   ���_�J�e�S��
    iv_lead_time_day          IN VARCHAR2,     --   ���Y����LT/����ύXLT
    iv_ship_date              IN VARCHAR2,     --   �o�ɓ�
    iv_base_record_class      IN VARCHAR2,     --   ����R�[�h�敪
    iv_prod_class             IN VARCHAR2,     --   ���i�敪
    ov_errbuf                 OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    cv_prod_class        CONSTANT VARCHAR2(1) :=  '1';    -- ���i�敪�u���[�t�v
    cv_prod_class2       CONSTANT VARCHAR2(1) :=  '2';    -- ���i�敪�u�h�����N�v
-- Ver1.2 M.Hokkanji Start
    cv_sales_branch_category_0 CONSTANT VARCHAR2(1)   := '0';  -- ���_�J�e�S���F0
-- Ver1.2 M.Hokkanji End
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
    lv_tighten_status VARCHAR2(1);     -- ���߃X�e�[�^�X
--
    -- *** ���[�J���ϐ� ***
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- WHO�J�����擾
    gt_user_id          := FND_GLOBAL.USER_ID;          -- �쐬�ҁA�ŏI�X�V��
    gt_login_id         := FND_GLOBAL.LOGIN_ID;         -- �ŏI�X�V���O�C��
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �A�v���P�[�V����ID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �v���O����ID
--
    gt_system_date      := SYSDATE;                     -- �V�X�e�����t
--
    -- **************************************************
    -- *** ���̓p�����[�^�`�F�b�N(K-1)
    -- **************************************************
--
--  �K�{�`�F�b�N
--
    -- �u���_�v����сu���_�J�e�S���v��NULL�̏ꍇ
    IF (iv_sales_branch IS NULL) AND (iv_sales_branch_category IS NULL) THEN
      -- ���_����ы��_�J�e�S���̕K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W���Z�b�g���܂�
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_sales_branch_category) || gv_line_feed;
    -- �u���_�v����сu���_�J�e�S���v�̗�����NULL�łȂ��ꍇ
    ELSIF (iv_sales_branch IS NOT NULL) AND (iv_sales_branch_category IS NOT NULL) THEN
      -- ������͍��ڃG���[���b�Z�[�W���Z�b�g���܂�
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_alternative_err) || gv_line_feed;
    -- �u���_�v�݂̂�NULL�łȂ��ꍇ
    ELSIF  (iv_sales_branch IS NOT NULL) AND (iv_sales_branch_category IS NULL) THEN
      -- �u���_�v�ݒ�
      gt_sales_branch := iv_sales_branch; -- ���_
      -- �u���_�J�e�S���v�ɁuALL�v��ݒ�
      gt_sales_branch_category := gv_all; -- ���_�J�e�S��
    -- �u���_�J�e�S���v�݂̂�NULL�łȂ��ꍇ
    ELSIF  (iv_sales_branch IS NULL) AND (iv_sales_branch_category IS NOT NULL) THEN
      -- �u���_�J�e�S���v�ݒ�
-- Ver1.2 M.Hokkanji Start
      -- ���_�J�e�S����0(ALL)�̏ꍇ��'ALL'�ɕύX
      IF ( iv_sales_branch_category = cv_sales_branch_category_0) THEN
        gt_sales_branch_category := gv_all; -- ���_�J�e�S��
      ELSE
        gt_sales_branch_category := iv_sales_branch_category; -- ���_�J�e�S��
      END IF;
-- Ver1.2 M.Hokkanji End
      -- �u���_�v�ɁuALL�v��ݒ�
      gt_sales_branch := gv_all; -- ���_
    END IF;
--
    -- �u���Y����LT/����ύXLT�v�`�F�b�N
    IF (iv_lead_time_day IS NULL) THEN
      -- ���Y����LT/����ύXLT��NULL�`�F�b�N���s���܂�
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_lead_time_day) || gv_line_feed;
    ELSE
      -- �u���Y����LT/����ύXLT�v�̏����ϊ�(NUMBER)
      gt_lead_time_day := TO_NUMBER(iv_lead_time_day);
    END IF;
--
    -- �u�o�ɓ��v�`�F�b�N
    IF (iv_ship_date IS NULL) THEN
      -- �o�ɓ���NULL�`�F�b�N���s���܂�
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_schedule_ship_date) || gv_line_feed;
    ELSE
      -- �u�o�ɓ��v�̏����ϊ�(YYYY/MM/DD)
      gt_schedule_ship_date := FND_DATE.STRING_TO_DATE(iv_ship_date,'YYYY/MM/DD');
      -- �ϊ��G���[��
      IF (gt_schedule_ship_date IS NULL) THEN
        lv_errmsg := lv_errmsg || xxcmn_common_pkg.get_msg( gv_xxwsh
                                                       ,gv_mst_format_err
                                                       ,gv_cnst_tkn_date
                                                       ,iv_ship_date
                                                      ) || gv_line_feed;
      END IF;
    END IF;
--
    -- �u����R�[�h�敪�v�`�F�b�N
    IF (iv_base_record_class IS NULL) THEN
      -- ����R�[�h�敪��NULL�`�F�b�N���s���܂�
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_base_record_class) || gv_line_feed;
    END IF;
--
--  �Ó����`�F�b�N
--
    -- �u���i�敪�v�Ó����`�F�b�N
    IF ((iv_prod_class <> cv_prod_class) AND (iv_prod_class <> cv_prod_class2)) THEN
      -- ���i�敪�敪��1�A2�ȊO�̃`�F�b�N���s���܂�
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_suitable_err) || gv_line_feed;
    ELSE
      gt_prod_class_type := iv_prod_class;
--
      -- ���i�敪��1�F�u���[�t�v�̏ꍇ
      IF (iv_prod_class = cv_prod_class) THEN
        -- �u�o�Ɍ`�ԁv�`�F�b�N
        IF (iv_transaction_type_id IS NULL) THEN
          -- �o�Ɍ`�Ԃ�NULL�`�F�b�N���s���܂�
          lv_errmsg := lv_errmsg ||
                   xxcmn_common_pkg.get_msg(gv_xxwsh,
                                            gv_need_param_err,
                                            gv_cnst_tkn_para,
                                            gv_tkn_transaction_type_id) || gv_line_feed;
        ELSE
          -- �u�󒍃^�C�vID�v�ݒ�
          gt_order_type_id         := TO_NUMBER(iv_transaction_type_id); -- �󒍃^�C�vID
        END IF;
      -- ���i�敪��2�F�u�h�����N�v�̏ꍇ
      ELSIF  (iv_prod_class = cv_prod_class2) THEN
        -- �u�󒍃^�C�vID�v�ݒ�
        IF (iv_transaction_type_id IS NULL) THEN
          -- �󒍃^�C�vID��NULL�̏ꍇ�A�u-999�v���Z�b�g
          gt_order_type_id         := TO_NUMBER(gv_dummy_order_type_id); -- �_�~�[�󒍃^�C�vID
        ELSE
          gt_order_type_id         := TO_NUMBER(iv_transaction_type_id); -- �󒍃^�C�vID
        END IF;
      END IF;
    END IF;
--
    -- �u�o�׌��ۊǏꏊ�v�ݒ�
    IF (iv_shipped_locat_code IS NULL) THEN
      -- �o�Ɍ���NULL�̏ꍇ�A�uALL�v���Z�b�g
      gt_deliver_from         := gv_all; -- ALL
    ELSE
      gt_deliver_from         := iv_shipped_locat_code; -- �o�Ɍ�
    END IF;
--
    -- �u����R�[�h�敪�v�ݒ�
    gt_base_record_class     := iv_base_record_class;     -- ����R�[�h�敪
--
    -- �u���߁^�����敪�v�ݒ�
    gt_tighten_release_class := gv_xxwsh_release_class;     -- ���߁^�����敪(2�F����)
--
    -- **************************************************
    -- *** ���b�Z�[�W�̐��`
    -- **************************************************
    -- ���b�Z�[�W���o�^����Ă���ꍇ
    IF (lv_errmsg IS NOT NULL) THEN
      -- �Ō�̉��s�R�[�h���폜��OUT�p�����[�^�ɐݒ�
      lv_errmsg := RTRIM(lv_errmsg, gv_line_feed);
      -- �G���[�Ƃ��ďI��
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���ߏ������{�`�F�b�N (K-2)
    -- ===============================
-- Ver1.2 M.Hokkanji Start
-- ���ߏ����ƒ��߉��������Ń`�F�b�N�𕪂���K�v�����邽�ߌĂԊ֐���ύX
--    lv_tighten_status := xxwsh_common_pkg.check_tightening_status(
    lv_tighten_status := check_tightening_status2(
-- Ver1.2 M.Hokkanji End
      gt_order_type_id,                --   �󒍃^�C�vID(�o�Ɍ`��)
      gt_deliver_from,                 --   �o�Ɍ��ۊǏꏊ
      gt_sales_branch,                 --   ���_
      gt_sales_branch_category,        --   ���_�J�e�S��
      gt_lead_time_day,                --   ���Y����LT/����ύXLT
      gt_schedule_ship_date,           --   �o�ɓ�
      gt_prod_class_type               --   ���i�敪
      );
--
    -- ���߃X�e�[�^�X���u1:���ߏ��������{�v�̏ꍇ�A���ߏ������{�G���[
    IF (lv_tighten_status = gv_tighten_status_1) THEN
      ov_retcode := gv_status_error;
      lv_errmsg := lv_errmsg ||
                 xxcmn_common_pkg.get_msg(gv_xxwsh,
                                          gv_tightening_err);
      RAISE global_process_expt;
    -- ���߃X�e�[�^�X���u3:���߉����ς݁v�̏ꍇ�A���߉����ς݃G���[
    ELSIF (lv_tighten_status = gv_tighten_status_3) THEN
      ov_retcode := gv_status_error;
      lv_errmsg := lv_errmsg ||
                 xxcmn_common_pkg.get_msg(gv_xxwsh,
                                          gv_released_err);
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- �������R�[�h�̓o�^(K-3)
    -- ==============================================
    ins_xxwsh_tightening_control(
                               lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                               lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                               lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    ELSIF (lv_retcode = gv_status_normal) THEN
      ov_retcode := lv_retcode;
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
--
  EXCEPTION
--
    --*** ���l�^�ɕϊ��ł��Ȃ������ꍇ=TO_NUMBER() ***
    WHEN VALUE_ERROR THEN
      gn_error_cnt := gn_error_cnt + 1;   -- �G���[�����J�E���g
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;   -- �G���[�����J�E���g
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;   -- �G���[�����J�E���g
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;   -- �G���[�����J�E���g
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
    errbuf                    OUT VARCHAR2,    --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                   OUT VARCHAR2,     --   ���^�[���E�R�[�h    --# �Œ� #
    iv_transaction_type_id    IN VARCHAR2,     --   �o�Ɍ`��
    iv_shipped_locat_code     IN VARCHAR2,     --   �o�Ɍ�
    iv_sales_branch           IN VARCHAR2,     --   ���_
    iv_sales_branch_category  IN VARCHAR2,     --   ���_�J�e�S��
    iv_lead_time_day          IN VARCHAR2,     --   ���Y����LT/����ύXLT
    iv_ship_date              IN VARCHAR2,     --   �o�ɓ�
    iv_base_record_class      IN VARCHAR2,     --   ����R�[�h�敪
    iv_prod_class             IN VARCHAR2      --   ���i�敪
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
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_transaction_type_id,       --   �o�Ɍ`��
      iv_shipped_locat_code,        --   �o�Ɍ�
      iv_sales_branch,              --   ���_
      iv_sales_branch_category,     --   ���_�J�e�S��
      iv_lead_time_day,             --   ���Y����LT/����ύXLT
      iv_ship_date,                 --   �o�ɓ�
      iv_base_record_class,         --   ����R�[�h�敪
      iv_prod_class,                --   ���i�敪
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�o�͌����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH',gv_output_msg,'CNT',TO_CHAR(gn_target_cnt));
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
END xxwsh400010c;
/
