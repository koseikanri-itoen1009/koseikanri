create or replace PACKAGE BODY xxwsh400004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh400004c(BODY)
 * Description            : �o�׈˗����ߊ֐�
 * MD.050                 : T_MD050_BPO_401_�o�׈˗�
 * MD.070                 : T_MD070_BPO_40E_�o�׈˗����ߊ֐�
 * Version                : 1.14
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  in_order_type_id         P         �o�Ɍ`��ID
 *  iv_deliver_from          P         �o�׌�
 *  iv_sales_base            P         ���_
 *  iv_sales_base_category   P         ���_�J�e�S��
 *  in_lead_time_day         P         ���Y����LT
 *  id_schedule_ship_date    P         �o�ɓ�
 *  iv_base_record_class     P         ����R�[�h�敪
 *  iv_request_no            P         �˗�No
 *  iv_tighten_class         P         ���ߏ����敪
 *  in_tightening_program_id P         ���߃R���J�����gID
 *  iv_tightening_status_chk_class
 *                           P         ���߃X�e�[�^�X�`�F�b�N�敪
 *  iv_callfrom_flg          P         �ďo���t���O
 *  iv_prod_class            P         ���i�敪
 *  iv_instruction_dept      P         ����
 * ------------- ----------- --------- --------------------------------------------------
 *  Date         Ver.  Editor          Description
 * ------------- ----- --------------- --------------------------------------------------
 *  2008/4/8     1.0   R.Matusita      �V�K�쐬
 *  2008/5/19    1.1   Oracle �㌴���D �����ύX�v��#80�Ή� �p�����[�^�u���_�v�ǉ�
 *  2008/5/21    1.2   Oracle �㌴���D �����e�X�g�o�O�C��
 *                                     �p�����[�^�u���ߏ����敪�v��NULL�̂Ƃ���'1'(�������)�Ƃ���
 *                                     �w�������擾����SQL�C��(�ڋq���VIEW���Q�Ƃ��Ȃ�)
 *                                     �ďo���t���O'2'(���)�̏ꍇ�̎擾SQL��ύX
 *                                     �i�˗�No�݂̂��L�[���ڂɍX�V�Ώۂ̃f�[�^���擾����)
 *  2008/6/06    1.3   Oracle �Γn���a ���[�h�^�C���`�F�b�N���̔����ύX
 *  2008/6/27    1.4   Oracle �㌴���D �����ۑ�56�Ή� �ďo������ʂ̏ꍇ�ɂ����ߊǗ��A�h�I���o�^
 *  2008/6/30    1.5   Oracle �k�������v ST�s��Ή�#326
 *  2008/7/01    1.6   Oracle �k�������v ST�s��Ή�#338
 *  2008/08/05   1.7   Oracle �R����_ �o�גǉ�_5�Ή�
 *  2008/10/10   1.8   Oracle �ɓ��ЂƂ� �����e�X�g�w�E239�Ή�
 *  2008/10/28   1.9   Oracle �ɓ��ЂƂ� �����e�X�g�w�E141�Ή�
 *  2008/11/14   1.10  SCS    �ɓ��ЂƂ� �����e�X�g�w�E650�Ή�
 *  2008/12/01   1.11  SCS    �������   �{�Ԏw�E253�Ή��i�b��j
 *  2008/12/07   1.12  SCS    �������   �{��#386
 *  2008/12/17   1.13  SCS    �㌴/���c  �{��#81
 *  2008/12/17   1.13  SCS    ���c       APP-XXWSH-11204�G���[�������ɑ����I�����Ȃ��悤�ɂ���
 *  2008/12/23   1.14  SCS    �㌴       �{��#81 �Ē��ߏ������̒��o�����Ƀ��[�h�^�C����ǉ�
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
  gv_msg_part      CONSTANT VARCHAR2(3) := ' :';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  --*** ���������ʗ�O���[�j���O ***
  global_process_warn       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gn_status_normal CONSTANT NUMBER := 0;
  gn_status_error  CONSTANT NUMBER := 1;
  gn_status_warn   CONSTANT NUMBER := 2;
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh400004c'; -- �p�b�P�[�W��
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  gv_cnst_sep_msg  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00003';  -- sep_msg
  gv_cnst_cmn_008  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00008';  -- ��������
  gv_cnst_cmn_009  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00009';  -- ��������
  gv_cnst_cmn_010  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00010';  -- �G���[����
  gv_cnst_cmn_011  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00011';  -- �X�L�b�v����
  gv_cnst_cmn_cnt  CONSTANT VARCHAR2(15)  := 'CNT';              -- CNT
--
  -- ���ڃ`�F�b�N
--
  gv_cnst_msg_fomt CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11211';  -- �}�X�^�����G���[���b�Z�[�W
  gv_cnst_msg_204  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11204';  -- ���ߏ������{�ς݃G���[
  gv_cnst_msg_205  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11205';  -- ���ߊ֐��p���ʊ֐��G���[
  gv_cnst_msg_206  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11206';  -- �ғ����`�F�b�N�G���[
  gv_cnst_msg_207  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11207';  -- ���[�h�^�C���`�F�b�N�G���[
  gv_cnst_msg_208  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11208';  -- �w�������擾�G���[
  gv_cnst_msg_null CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11201';  -- �K�{�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_222  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11224';  -- ����I���`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_prop CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11210';  -- �Ó����`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_001  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11202';  -- ۯ��װ
  gv_cnst_msg_002  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11212';  -- �Ώۃf�[�^�Ȃ�
  gv_cnst_msg_003  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11213';  -- ���������o��
  gv_cnst_msg_220  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11220';  -- ���폈�������o��
  gv_cnst_msg_221  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11221';  -- �x�����������o��
--
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';
--                                            -- ���b�Z�[�W�F���b�N�擾�G���[
  gv_cnst_token_api_name  CONSTANT VARCHAR2(15)  := 'API_NAME';
--
  gv_cnst_tkn_table       CONSTANT VARCHAR2(15)  := 'TABLE';
  gv_cnst_tkn_item        CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value       CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_file_id_name    CONSTANT VARCHAR2(7)   := 'FILE_ID';
  gv_cnst_tkn_para        CONSTANT VARCHAR2(9)   := 'PARAMETER';
--
  gv_status_01            CONSTANT VARCHAR2(2)   := '01';    -- ���͒�
  gv_status_02            CONSTANT VARCHAR2(2)   := '02';    -- ���_�m��
  gv_status_03            CONSTANT VARCHAR2(2)   := '03';    -- ���ߍς�
  gv_line_feed            CONSTANT VARCHAR2(1)   := CHR(10); -- ���s�R�[�h;
--
  gv_msg_null_01          CONSTANT VARCHAR2(30)  := '����R�[�h�敪';
  gv_msg_null_02          CONSTANT VARCHAR2(30)  := '���ߏ����敪';
  gv_msg_null_03          CONSTANT VARCHAR2(30)  := '�ďo���t���O';
  gv_msg_null_04          CONSTANT VARCHAR2(30)  := '���߃X�e�[�^�X�敪';
  gv_msg_null_06          CONSTANT VARCHAR2(30)  := '���߃X�e�[�^�X�`�F�b�N�敪';
  gv_msg_null_08          CONSTANT VARCHAR2(30)  := '�o�ɓ�';
  gv_msg_null_05          CONSTANT VARCHAR2(30)  := '�˗�No';
  gv_msg_null_07          CONSTANT VARCHAR2(30)  := '�o�Ɍ`��';
  gv_msg_null_10          CONSTANT VARCHAR2(30)  := '���Y����LT/����ύXLT';
  gv_msg_null_11          CONSTANT VARCHAR2(30)  := '���߃R���J�����gID';
-- 2008/11/14 H.Itou Add Start �����e�X�g�w�E650 ���ד���ғ����x���̎���OUT�p�����[�^.�G���[���b�Z�[�W�ɕԂ����b�Z�[�W
  gv_msg_warn_01          CONSTANT VARCHAR2(30)  := '�ғ���';
-- 2008/11/14 H.Itou Add End
  gv_status_A             CONSTANT VARCHAR2(1)   := 'A'; -- �L��
  gn_m999                 CONSTANT NUMBER        := -999;
  gv_ALL                  CONSTANT VARCHAR2(3)   := 'ALL';
  gv_sales_base_category_0 CONSTANT VARCHAR2(3)   := '0';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �X�V�pPL/SQL�\�^
  TYPE order_header_id_ttype    IS TABLE OF
  xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER; -- �󒍃w�b�_�A�h�I��ID
--
  -- �X�V�pPL/SQL�\
  gt_header_id_upd_tab    order_header_id_ttype; -- �󒍃w�b�_�A�h�I��ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gn_target_cnt      NUMBER;                    -- �Ώی���
  gn_normal_cnt      NUMBER;                    -- ���팏��
  gn_error_cnt       NUMBER;                    -- �G���[����
  gn_warn_cnt        NUMBER;                    -- �X�L�b�v����
  gv_callfrom_flg    VARCHAR2(1);               -- �ďo���t���O
  gv_party_number    VARCHAR2(30);              -- �g�D�ԍ�
  gn_user_id         NUMBER;                    -- ���O�C�����Ă��郆�[�U�[
  gn_login_id        NUMBER;                    -- �ŏI�X�V���O�C��
  gv_sales_base_category VARCHAR2(3);           -- ���_�J�e�S��
  gv_base_record_class VARCHAR2(2);             -- ����R�[�h�敪
  gn_conc_request_id NUMBER;                    -- �v��ID
  gn_prog_appl_id    NUMBER;                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_conc_program_id NUMBER;                    -- �R���J�����g�E�v���O����ID
--
   /**********************************************************************************
   * Procedure Name   : insert_tightening_control
   * Description      : ���ߍς݃��R�[�h�o�^ (E-5)
   ***********************************************************************************/
  PROCEDURE insert_tightening_control(
    in_order_type_id         IN  NUMBER    DEFAULT NULL, -- �o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- �o�׌�
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- ���_
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- ���_�J�e�S��
    in_lead_time_day         IN  NUMBER    DEFAULT NULL, -- ���Y����LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- �o�ɓ�
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- ���i�敪
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- ����R�[�h�敪
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'insert_tightening_control'; -- �v���O������
    cv_tighten_release_class_1       VARCHAR2(1)  := '1'; -- ����/�����敪 ����
    cv_base_record_class_Z           VARCHAR2(1)    := 'Z'; -- ����R�[�h�敪Z
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
    ln_transaction_id   NUMBER DEFAULT 0;
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
    SELECT xxwsh_tightening_control_s1.NEXTVAL       -- �g�����U�N�V����ID
    INTO   ln_transaction_id
    FROM   dual;
--
    -- ����R�[�h�敪��'Z'�̏ꍇ�A�R���J�����gID��'-(�}�C�i�X)�g�����U�N�V����ID'���Z�b�g����B
    IF (iv_base_record_class = cv_base_record_class_Z) THEN
      gn_conc_request_id := - ln_transaction_id;
--      gn_conc_program_id := - ln_transaction_id;
    END IF;
    -- =====================================
    -- �o�׈˗����ߊǗ��i�A�h�I���j�o�^
    -- =====================================
    INSERT INTO xxwsh_tightening_control
       (transaction_id
      , concurrent_id
      , order_type_id
      , deliver_from
      , prod_class
      , sales_branch
      , sales_branch_category
      , lead_time_day
      , schedule_ship_date
      , tighten_release_class
      , tightening_date
      , base_record_class
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date)
    VALUES(
        ln_transaction_id             -- �g�����U�N�V����ID
      , gn_conc_request_id            -- �R���J�����gID
      , NVL(in_order_type_id,gn_m999) -- �󒍃^�C�vID
      , NVL(iv_deliver_from,gv_ALL)   -- �o�׌��ۊǏꏊ
      , NVL(iv_prod_class,gv_ALL)     -- ���i�敪
      , NVL(iv_sales_base,gv_ALL)     -- ���_
      , NVL(gv_sales_base_category,gv_ALL) -- ���_�J�e�S��
      , NVL(in_lead_time_day,gn_m999) -- ���Y����LT
      , NVL(id_schedule_ship_date,SYSDATE) -- �o�ח\���
      , cv_tighten_release_class_1    -- ����/�����敪 1�F����
      , SYSDATE                       -- ���ߎ��{����
      , iv_base_record_class          -- ����R�[�h�敪
      , gn_user_id                    -- �쐬��
      , SYSDATE                       -- �쐬��
      , gn_user_id                    -- �ŏI�X�V��
      , SYSDATE                       -- �ŏI�X�V��
      , gn_login_id                   -- �ŏI�X�V���O�C��
      , gn_conc_request_id            -- �v��ID
      , gn_prog_appl_id               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , gn_conc_program_id            -- �R���J�����g�E�v���O����ID
      , SYSDATE);                     -- �v���O�����X�V��
--
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
  END insert_tightening_control;
--
   /**********************************************************************************
   * Procedure Name   : delete_tightening_control
   * Description      : ���߉������R�[�h�폜 (E-8)
   ***********************************************************************************/
  PROCEDURE delete_tightening_control(
    ln_conc_request_id       IN  NUMBER,                 -- �R���J�����gID
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'delete_tightening_control'; -- �v���O������
    cv_tighten_release_class_2       VARCHAR2(1)  := '2'; -- ����/�����敪 ����
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
    -- �\���b�N�擾
    CURSOR get_tab_lock_cur
    IS
      SELECT  transaction_id
      FROM    xxwsh_tightening_control
      WHERE   concurrent_id         = ln_conc_request_id          -- �R���J�����gID
      AND     tighten_release_class = cv_tighten_release_class_2  -- ����/�����敪 2�F����
      FOR UPDATE NOWAIT
      ;
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
      WHEN check_lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn   -- ���W���[�������́FXXCMN �}�X�^�E�o������
                     ,gv_msg_xxcmn10146 -- ���b�Z�[�W�F���b�N�擾�G���[
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- �o�׈˗����ߊǗ��i�A�h�I���j�폜
    -- =====================================
    DELETE FROM xxwsh_tightening_control
    WHERE concurrent_id         = ln_conc_request_id          -- �R���J�����gID
    AND   tighten_release_class = cv_tighten_release_class_2; -- ����/�����敪 2�F����
--
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
  END delete_tightening_control;
--
   /**********************************************************************************
   * Procedure Name   : get_party_number
   * Description      : �w�������擾����
   ***********************************************************************************/
  PROCEDURE get_party_number(
    id_schedule_ship_date IN  DATE,                   -- �o�ɓ�
    ov_party_number       OUT NOCOPY VARCHAR2,        -- �g�D�ԍ�
    ov_user_name          OUT NOCOPY VARCHAR2,        -- ���[�U�[��
    ov_errbuf             OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'get_party_number';       -- �v���O������
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
    cv_customer_class_code VARCHAR2(1) := '1';
    -- *** ���[�J���ϐ� ***
--
    ln_user_id             NUMBER;                -- ���O�C�����Ă��郆�[�U�[��ID�擾
    lv_party_number        VARCHAR2(30)  := NULL; -- �g�D�ԍ�
    lv_user_name           VARCHAR2(100) := NULL; -- ���[�U�[��
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
    SELECT xlv.location_code,fu.user_name
    INTO   lv_party_number,lv_user_name
    FROM   xxcmn_locations2_v        xlv    -- ���Ə����VIEW2
          ,per_all_assignments_f     paaf   -- �]�ƈ������}�X�^
          ,fnd_user                  fu     -- ���[�U�[�}�X�^
    WHERE  fu.user_id                =  gn_user_id
    AND    paaf.person_id            =  fu.employee_id
    AND    paaf.primary_flag         =  'Y'
    AND    paaf.effective_start_date <= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    paaf.effective_end_date   >= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    xlv.start_date_active     <= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    xlv.end_date_active       >= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    xlv.inactive_date         Is Null
    AND    xlv.location_id           =  paaf.location_id;
--
    ov_party_number := lv_party_number;
    ov_user_name    := lv_user_name;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_party_number := NULL;
      ov_user_name    := NULL;
      ov_retcode      := gv_status_error;
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
  END get_party_number;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_batch
   * Description      : �X�e�[�^�X�ꊇ�X�V����(E-7)
   ***********************************************************************************/
  PROCEDURE upd_table_batch(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_table_batch'; -- �v���O������
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
    -- ���ʍX�V���̎擾
--
    -- =====================================
    -- �ꊇ�X�V����
    -- =====================================
    FORALL ln_cnt IN 1 .. gt_header_id_upd_tab.COUNT
      -- �󒍃w�b�_�A�h�I���X�V(���ߍς�)
      UPDATE xxwsh_order_headers_all
      SET req_status              = gv_status_03                   -- �X�e�[�^�X(03:���ߍς�)
         ,instruction_dept        = gv_party_number                -- E-2�g�D�ԍ�
         ,tightening_program_id   = gn_conc_request_id             -- �v��ID
         ,last_updated_by         = gn_user_id                     -- �ŏI�X�V��
         ,last_update_date        = SYSDATE                        -- �ŏI�X�V��
         ,last_update_login       = gn_login_id                    -- �ŏI�X�V���O�C��
         ,request_id              = gn_conc_request_id             -- �v��ID
         ,program_application_id  = gn_prog_appl_id                -- �ݶ��āE��۸��сE���ع����ID
         ,program_id              = gn_conc_program_id             -- �R���J�����g�E�v���O����ID
         ,program_update_date     = SYSDATE                        -- �v���O�����X�V��
      WHERE order_header_id       = gt_header_id_upd_tab(ln_cnt);  -- �󒍃w�b�_�A�h�I��ID
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
  END upd_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : out_log
   * Description      : �����o�͏���
   ***********************************************************************************/
  PROCEDURE out_log(
    in_target_cnt   IN NUMBER,  --   ��������
    in_normal_cnt   IN NUMBER,  --   ��������
    in_error_cnt    IN NUMBER,  --   �G���[����
    in_warn_cnt     IN NUMBER)  --   �X�L�b�v����
  IS
--
  BEGIN
--
--
    IF (gv_callfrom_flg = 1) THEN
--    �Ăяo�����t���O���P�F�R���J�����g�̏ꍇ�̓��O�o�͂���
--
      -- ==================================
      -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
      -- ==================================
--
      gn_target_cnt := in_target_cnt;
      gn_normal_cnt := in_normal_cnt;
      gn_error_cnt  := in_error_cnt;
      gn_warn_cnt   := in_warn_cnt;
--
      --���������o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                             gv_cnst_cmn_008,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_target_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --���팏���o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                             gv_cnst_msg_220,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_normal_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --�G���[�����o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                             gv_cnst_cmn_010,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_error_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --�x�������o��
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                             gv_cnst_msg_221,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_warn_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --��؂蕶���o��
      gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,gv_cnst_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
      gn_warn_cnt   := 0;
--
  END out_log;
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾
   ***********************************************************************************/
  PROCEDURE init_proc(
    id_schedule_ship_date     IN   DATE,                -- �o�ɓ�
    ln_transaction_type_id    OUT  NUMBER,              -- �^�C�vID
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'init_proc';       -- �v���O������
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
    cv_app_name             CONSTANT VARCHAR2(5)  := 'XXWSH';             -- �A�v���P�[�V�����Z�k��
    cv_msg_ng_data          CONSTANT VARCHAR2(15) := 'APP-XXWSH-11223';   -- �Ώۃf�[�^�Ȃ�
    cv_tkn_item             CONSTANT VARCHAR2(15) := 'ITEM';              -- �g�[�N���F�Ώۖ�
    cv_format_type          CONSTANT VARCHAR2(20) := '�t�H�[�}�b�g�p�^�[��';
    cv_tkn_value            CONSTANT VARCHAR2(15) := 'VALUE';             -- �g�[�N���F�l
--
    -- �v���t�@�C��
    cv_tran_type_plan       CONSTANT VARCHAR2(30) := 'XXWSH_TRAN_TYPE_PLAN';
    -- *** ���[�J���ϐ� ***
    lv_tran_type_plan           VARCHAR2(100);   -- �v���t�@�C���F�����ύX
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
    -- ***************************************
    -- ***         �v���t�@�C���擾        ***
    -- ***************************************
    -- �v���t�@�C���u�����ύX�v�擾
    lv_tran_type_plan := FND_PROFILE.VALUE(cv_tran_type_plan);
--
--
    -- �^�C�vID�擾
    BEGIN
      SELECT  transaction_type_id
      INTO    ln_transaction_type_id
      FROM    xxwsh_oe_transaction_types2_v -- �󒍃^�C�v���VIEW2
      WHERE   transaction_type_name =  lv_tran_type_plan
      AND     start_date_active    <= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
      AND     (end_date_active     IS NULL
      OR       end_date_active     >= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
              )
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                           -- *** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(
                            cv_app_name,                -- �A�v���P�[�V�����Z�k���FXXINV
                            cv_msg_ng_data,             -- APP-XXINV-10008�F�Ώۃf�[�^�Ȃ�
                            cv_tkn_item,                -- �g�[�N���F�Ώۖ�
                            cv_format_type,             -- �t�H�[�}�b�g�p�^�[��
                            cv_tkn_value,               -- �g�[�N���F�l
                            lv_tran_type_plan);         -- �t�@�C���t�H�[�}�b�g
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : �o�׈˗�����
   * Description      : ship_tightening
   ***********************************************************************************/
  PROCEDURE ship_tightening(
    in_order_type_id         IN  NUMBER    DEFAULT NULL, -- �o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- �o�׌�
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- ���_
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- ���_�J�e�S��
    in_lead_time_day         IN  NUMBER    DEFAULT NULL, -- ���Y����LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- �o�ɓ�
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- ����R�[�h�敪
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- �˗�No
    iv_tighten_class         IN  VARCHAR2  DEFAULT NULL, -- ���ߏ����敪
    in_tightening_program_id IN  NUMBER    DEFAULT NULL, -- ���߃R���J�����gID
    iv_tightening_status_chk_class
                             IN  VARCHAR2,               -- ���߃X�e�[�^�X�`�F�b�N�敪
    iv_callfrom_flg          IN  VARCHAR2,               -- �ďo���t���O
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- ���i�敪
    iv_instruction_dept      IN  VARCHAR2  DEFAULT NULL, -- ����
    ov_errbuf                OUT NOCOPY  VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY  VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY  VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT          VARCHAR2(100)  := 'ship_tightening'; -- �v���O������
    cv_order_category_code           VARCHAR2(5)    := 'ORDER';           -- ��
    cv_shipping_shikyu_class         VARCHAR2(1)    := '1';               -- �o�׈˗�
    cv_get_oprtn_day_api             VARCHAR2(50)   := '�ғ����Z�o�֐�';
    cv_get_oprtn_day_lt              VARCHAR2(50)   := '���Y����LT�^����ύXLT';
    cv_calc_lead_time_api            VARCHAR2(50)   := '���[�h�^�C���Z�o';
    cv_get_oprtn_day_lt2             VARCHAR2(50)   := '�z�����[�h�^�C��';
--
    cv_order_type_id_04              VARCHAR2(2)    := '04';  -- ����ύX
    cv_customer_class_code_1         VARCHAR2(1)    := '1'; -- �ڋq�敪
    cv_code_class_4                  VARCHAR2(1)    := '4'; -- 1�F�q��
    cv_code_class_9                  VARCHAR2(1)    := '9'; -- 9�F�z����
    cv_code_class_1                  VARCHAR2(1)    := '1'; -- 1�F���_
    cv_prod_class_2                  VARCHAR2(1)    := '2'; -- 2�F�h�����N
    cv_prod_class_1                  VARCHAR2(1)    := '1'; -- 1�F���[�t
    cv_tighten_class_1               VARCHAR2(1)    := '1'; -- ���ߏ����敪1:����
    cv_tighten_class_2               VARCHAR2(1)    := '2'; -- ���ߏ����敪2:��
    cv_tightening_status_chk_cla_1   VARCHAR2(1)    := '1'; -- ���߃X�e�[�^�X�`�F�b�N�敪1
    cv_tightening_status_chk_cla_2   VARCHAR2(1)    := '2'; -- ���߃X�e�[�^�X�`�F�b�N�敪2
    cv_tightening_status_chk_cla_0   VARCHAR2(1)    := '0'; -- ���߃X�e�[�^�X�`�F�b�N�敪0
    cv_base_record_class_Y           VARCHAR2(1)    := 'Y'; -- ����R�[�h�敪Y
    cv_base_record_class_N           VARCHAR2(1)    := 'N'; -- ����R�[�h�敪N
    cv_base_record_class_Z           VARCHAR2(1)    := 'Z'; -- ����R�[�h�敪Z
    cv_callfrom_flg_1                VARCHAR2(1)    := '1'; -- �ďo���t���O1
    cv_callfrom_flg_2                VARCHAR2(1)    := '2'; -- �ďo���t���O2
    cv_status_2                      VARCHAR2(1)    := '2'; -- ���߃X�e�[�^�X2
    cv_status_4                      VARCHAR2(1)    := '4'; -- ���߃X�e�[�^�X4
    cv_deliver_from_4                VARCHAR2(1)    := '4'; -- �q��4
    cv_deliver_to_9                  VARCHAR2(1)    := '9'; -- �z����9
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
--
    -- *** ���[�J���ϐ� ***
--
    ln_retcode                       NUMBER DEFAULT 0; -- ���^�[���R�[�h
--
    ld_oprtn_day                     DATE;         -- �ғ������t
    ld_sysdate                       DATE;         -- �V�X�e�����t
    ld_schedule_ship_date            DATE;         -- �o�ɓ�
    ln_data_cnt                      NUMBER := 0;  -- �f�[�^����
    ln_target_cnt                    NUMBER := 0;  -- ��������
    ln_normal_cnt                    NUMBER := 0;  -- ���팏��
    ln_warn_cnt                      NUMBER := 0;  -- ���[�j���O��������
    lv_err_message                   VARCHAR2(4000); -- �G���[���b�Z�[�W
--
    ln_lead_time                     NUMBER;       -- ���Y����LT�^����ύXLT
    ln_delivery_lt                   NUMBER;       -- �z��LT
    lv_status                        VARCHAR2(2);  -- ���߃X�e�[�^�X
    ln_bfr_order_header_id           NUMBER DEFAULT 0;  -- �󒍃w�b�_�A�h�I��ID
    ln_order_header_id_lock          NUMBER;            -- �󒍃w�b�_�A�h�I��ID(���b�N�p)  2008/12/17 �{�ԏ�Q#81 Add
--
    ln_deliver_from_nullflg          NUMBER;       -- �o�׌�NULL�`�F�b�N�t���O
    ln_prod_class_nullflg            NUMBER;       -- ���i�敪NULL�`�F�b�N�t���O
    ln_request_no_nullflg            NUMBER;       -- �˗�NoNULL�`�F�b�N�t���O
    ln_schedule_ship_date_nullflg    NUMBER;       -- �o�ɓ�NULL�`�F�b�N�t���O
    ln_drink_base_category_flg       NUMBER;       -- �h�����N���_�J�e�S���t���O
    ln_leaf_base_category_flg        NUMBER;       -- ���[�t���_�J�e�S���t���O
    ln_tightening_prog_id_nullflg    NUMBER;       -- ���߃R���J�����gIDNULL�`�F�b�N�t���O
    ln_order_type_id_nullflg         NUMBER;       -- �o�Ɍ`��IDNULL�`�F�b�N�t���O
    ln_lock_error_flg                NUMBER;       -- ���b�N�G���[�t���O                    2008/12/17 �{�ԏ�Q#81 Add
    ln_stschk_error_flg              NUMBER;       -- ���߃X�e�[�^�X�`�F�b�N�G���[�t���O    2008/12/17 Add V1.13 APP-XXWSH-11204�G���[�������ɑ����I�����Ȃ��悤�ɂ���
    lv_user_name                     VARCHAR2(100); -- ���[�U�[��
    ln_transaction_type_id           NUMBER;       -- �^�C�vID
    -- ���ISQL�i�[�p
    lv_sql                           VARCHAR2(32000);
    lv_lead_time_w                   VARCHAR2(32000);
--
    -- �Ώۈ˗�No�ɂ��擾�p�i��ʁj
    cv_main_sql                      CONSTANT VARCHAR2(32000) :=
       ' SELECT
            xoha.tightening_program_id tightening_program_id -- ���߃R���J�����gID
           ,xoha.order_type_id         order_type_id         -- �󒍃^�C�vID
           ,NULL                       lead_time_day         -- ����ύXLT
           ,NVL(xoha.shipped_date,xoha.schedule_ship_date)    schedule_ship_date    -- �o�ח\���
           ,NVL(xoha.arrival_date,xoha.schedule_arrival_date) schedule_arrival_date -- ���ח\���
           ,NVL(xoha.result_deliver_to,xoha.deliver_to) deliver_to            -- �o�א�
           ,xoha.deliver_from          deliver_from          -- �o�׌��ۊǏꏊ
           ,xoha.prod_class            prod_class            -- ���i�敪
           ,xoha.request_no            request_no            -- �˗�No
           ,xoha.order_header_id       order_header_id       -- �󒍃w�b�_�A�h�I��ID
         FROM
           xxwsh_order_headers_all       xoha           -- �󒍃w�b�_�A�h�I��
         WHERE
           xoha.request_no         =  :iv_request_no    -- �˗�No
--2008/12/07 D.Sugahara Mod Start
         FOR UPDATE OF xoha.order_header_id  SKIP LOCKED '
--         FOR UPDATE OF xoha.order_header_id NOWAIT
--2008/12/07 D.Sugahara Mod End
      ;
    -- ���ߏ���
-- 2008/12/17 mod start ver1.13 M_Uehara
    cv_main_sql1                   CONSTANT VARCHAR2(32000) :=
        'SELECT
              tightening_program_id,            -- ���߃R���J�����gID
              order_type_id,                    -- �󒍃^�C�vID
              lead_time_day,                    -- ���[�h�^�C��
              schedule_ship_date,               -- �o�ח\���
              schedule_arrival_date,            -- ���ח\���
              deliver_to,                       -- �z����
              deliver_from,                     -- �o�Ɍ�
              prod_class,                       -- ���i�敪
              request_no,                       -- �˗�No
              order_header_id                   -- �󒍃w�b�_�A�h�I��ID
         FROM (
           -- �z��LT�i�q�ɁE�z����j�Ŏ擾
           SELECT
             xoha.tightening_program_id tightening_program_id
                                           -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.���߃R���J�����gID
           , xoha.order_type_id         order_type_id
                                           -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.�󒍃^�C�vID
           , CASE xottv.transaction_type_id -- �󒍃^�C�v
               WHEN :ln_transaction_type_id THEN
                    -- ����ύX
                    xdl.receipt_change_lead_time_day  -- �������ύXLT�i�q�ɁE�z����j
               ELSE
                    -- ����ύX�ȊO
                DECODE(xoha.prod_class,:cv_prod_class_2,  -- �h�����N���Y����LT
                       xdl.drink_lead_time_day     --�h�����N���Y����LT�i�q�ɁE�z����j
                                       ,:cv_prod_class_1,  -- ���[�t���Y����LT
                        xdl.leaf_lead_time_day       -- ���[�t���Y����LT�i�q�ɁE�z����j
                       )
             END                        lead_time_day -- ���[�h�^�C��
           , xoha.schedule_ship_date    schedule_ship_date
                                                          -- �o�ɓ� - �󒍃w�b�_�A�h�I��.�o�ח\���
           , xoha.schedule_arrival_date schedule_arrival_date
                                                          -- ���� - �󒍃w�b�_�A�h�I��.���ח\���
           , xoha.deliver_to            deliver_to
                                                          -- �z����R�[�h - �󒍃w�b�_�A�h�I��.�o�א�
           , xoha.deliver_from          deliver_from
                                          -- �o�׌��ۊǏꏊ�R�[�h - �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
           , xoha.prod_class            prod_class
                                                          -- ���i�敪 - �󒍃w�b�_�A�h�I��.���i�敪
           , xoha.request_no            request_no
                                                          -- �˗�No - �󒍃w�b�_�A�h�I��.�˗�No
           , xoha.order_header_id       order_header_id   -- �󒍃w�b�_�A�h�I��ID
           FROM
             xxwsh_oe_transaction_types2_v xottv    --�@�󒍃^�C�v���VIEW2
            ,xxwsh_order_headers_all       xoha     --�A�󒍃w�b�_�A�h�I��
            ,xxcmn_cust_accounts2_v        xcav
            ,xxcmn_cust_acct_sites2_v      xcasv
            ,(SELECT DISTINCT
                  lt.code_class1                  code_class1,
                                                                --�R�[�h�敪1�i�q�ɁE�z����j
                  lt.entering_despatching_code1   entering_despatching_code1,
                                                                --���o�ɏꏊ�R�[�h�P�i�q�ɁE�z����j
                  lt.code_class2                  code_class2,
                                                                --�R�[�h�敪2�i�q�ɁE�z����j
                  lt.entering_despatching_code2   entering_despatching_code2,
                                                                --���o�ɏꏊ�R�[�h2�i�q�ɁE�z����j
                  lt.drink_lead_time_day          drink_lead_time_day,
                                                                --�h�����N���Y����LT�i�q�ɁE�z����j
                  lt.leaf_lead_time_day           leaf_lead_time_day,
                                                                --���[�t���Y����LT�i�q�ɁE�z����j
                  lt.receipt_change_lead_time_day receipt_change_lead_time_day,
                                                                --�������ύXLT�i�q�ɁE�z����j
                  lt.lt_start_date_active         lt_start_date_active,
                  lt.lt_end_date_active           lt_end_date_active
             FROM
                   xxcmn_delivery_lt2_v          lt    --�z��L/T�A�h�I���}�X�^�i�q�ɁE�z����j
             WHERE lt.code_class1                   = :cv_code_class_4 --�R�[�h�敪1�F�q��
             AND   lt.code_class2                   = :cv_code_class_9 --�R�[�h�敪2�F�z����
           )                           xdl    --�z��L/T�A�h�I���}�X�^�i�q�ɁE�z����j
           ';
/**
    cv_main_sql1                   CONSTANT VARCHAR2(32000) :=
       ' SELECT
           xoha.tightening_program_id tightening_program_id
                                         -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.���߃R���J�����gID
         , xoha.order_type_id         order_type_id
                                         -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.�󒍃^�C�vID
         , CASE xottv.transaction_type_id -- �󒍃^�C�v
             WHEN :ln_transaction_type_id THEN
                  -- ����ύX
              NVL(xdl.lt1_rcpt_cng_lead_time_day  -- �������ύXLT�i�q�ɁE�z����j
                 ,xdl.lt2_rcpt_cng_lead_time_day) -- �������ύXLT�i�q�ɁE���_�j
             ELSE
                  -- ����ύX�ȊO
              DECODE(xoha.prod_class,:cv_prod_class_2,  -- �h�����N���Y����LT
                     NVL(xdl.lt1_drink_lead_time_day     --�h�����N���Y����LT�i�q�ɁE�z����j
                       , xdl.lt2_drink_lead_time_day)     --�h�����N���Y����LT�i�q�ɁE���_�j
                                     ,:cv_prod_class_1,  -- ���[�t���Y����LT
                      NVL(xdl.lt1_leaf_lead_time_day       -- ���[�t���Y����LT�i�q�ɁE�z����j
                       , xdl.lt2_leaf_lead_time_day)      -- ���[�t���Y����LT�i�q�ɁE���_�j
                     )
           END                        lead_time_day -- ���[�h�^�C��
         , xoha.schedule_ship_date    schedule_ship_date
                                                        -- �o�ɓ� - �󒍃w�b�_�A�h�I��.�o�ח\���
         , xoha.schedule_arrival_date schedule_arrival_date
                                                        -- ���� - �󒍃w�b�_�A�h�I��.���ח\���
         , xoha.deliver_to            deliver_to
                                                        -- �z����R�[�h - �󒍃w�b�_�A�h�I��.�o�א�
         , xoha.deliver_from          deliver_from
                                        -- �o�׌��ۊǏꏊ�R�[�h - �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
         , xoha.prod_class            prod_class
                                                        -- ���i�敪 - �󒍃w�b�_�A�h�I��.���i�敪
         , xoha.request_no            request_no
                                                        -- �˗�No - �󒍃w�b�_�A�h�I��.�˗�No
         , xoha.order_header_id       order_header_id   -- �󒍃w�b�_�A�h�I��ID
         FROM
           xxwsh_oe_transaction_types2_v xottv    --�@�󒍃^�C�v���VIEW2
          ,xxwsh_order_headers_all       xoha     --�A�󒍃w�b�_�A�h�I��
          ,xxcmn_cust_accounts2_v        xcav     --�C�ڋq���VIEW2
          ,xxcmn_cust_accounts2_v        xcav2    --�ڋq���VIEW2-2
          ,xxcmn_cust_acct_sites2_v      xcasv2'; --�ڋq�T�C�g���VIEW2-2
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
    cv_retable                     CONSTANT VARCHAR2(32000) :=
        ' ,xxwsh_tightening_control      xtc';    --�o�׈˗����ߊǗ��i�A�h�I���j
--
-- 2008/12/17 del start ver1.13 M_Uehara
/**
    cv_main_sql2                   CONSTANT VARCHAR2(32000) :=
     '   ,(SELECT DISTINCT
             lt2.code_class1                  lt2_code_class1,
                                                   --�R�[�h�敪�P�i�q�ɁE�z����j
             lt2.entering_despatching_code1   lt2_entering_despatching_code1,
                                                               --���o�ɏꏊ�R�[�h�P�i�q�ɁE�z����j
             lt1.code_class2                  lt1_code_class2,
                                                               --�R�[�h�敪�Q�i�q�ɁE�z����j
             lt1.entering_despatching_code2   lt1_entering_despatching_code2,
                                                               --���o�ɏꏊ�R�[�h�Q�i�q�ɁE�z����j
             lt2.code_class2                  lt2_code_class2,
                                                               --�R�[�h�敪�Q�i�q�ɁE���_�j
             lt2.entering_despatching_code2   lt2_entering_despatching_code2,
                                                               --���o�ɏꏊ�R�[�h�Q�i�q�ɁE���_�j
             lt1.drink_lead_time_day          lt1_drink_lead_time_day,
                                                               --�h�����N���Y����LT�i�q�ɁE�z����j
             lt1.leaf_lead_time_day           lt1_leaf_lead_time_day,
                                                               --���[�t���Y����LT�i�q�ɁE�z����j
             lt1.receipt_change_lead_time_day lt1_rcpt_cng_lead_time_day,
                                                               --�������ύXLT�i�q�ɁE�z����j
             lt2.drink_lead_time_day          lt2_drink_lead_time_day,
                                                               --�h�����N���Y����LT�i�q�ɁE���_�j
             lt2.leaf_lead_time_day           lt2_leaf_lead_time_day,
                                                               --���[�t���Y����LT�i�q�ɁE���_�j
             lt2.receipt_change_lead_time_day lt2_rcpt_cng_lead_time_day,
                                                               --�������ύXLT�i�q�ɁE���_�j
             lt1.lt_start_date_active         lt1_start_date_active,
             lt1.lt_end_date_active           lt1_end_date_active,
             lt2.lt_start_date_active         lt2_start_date_active,
             lt2.lt_end_date_active           lt2_end_date_active,
             lt2.xcav_start_date_active       xcav_start_date_active,
             lt2.xcav_end_date_active         xcav_end_date_active,
             lt2.xcasv_start_date_active      xcasv_start_date_active,
             lt2.xcasv_end_date_active        xcasv_end_date_active
           FROM
          (SELECT DISTINCT
                lt.code_class1                  code_class1,
                                                              --�R�[�h�敪1�i�q�ɁE���_�j
                lt.entering_despatching_code1   entering_despatching_code1,
                                                              --���o�ɏꏊ�R�[�h�P�i�q�ɁE���_�j
                lt.code_class2                  code_class2,
                                                              --�R�[�h�敪2�i�q�ɁE���_�j
                lt.entering_despatching_code2   entering_despatching_code2,
                                                              --���o�ɏꏊ�R�[�h2�i�q�ɁE���_�j
                lt.drink_lead_time_day          drink_lead_time_day,
                                                              --�h�����N���Y����LT�i�q�ɁE���_�j
                lt.leaf_lead_time_day           leaf_lead_time_day,
                                                              --���[�t���Y����LT�i�q�ɁE���_�j
                lt.receipt_change_lead_time_day receipt_change_lead_time_day,
                                                              --�������ύXLT�i�q�ɁE���_�j
                xcav.party_number               party_number,
                xcasv.party_site_number         party_site_number,
                lt.lt_start_date_active         lt_start_date_active,
                lt.lt_end_date_active           lt_end_date_active,
                xcav.start_date_active          xcav_start_date_active,
                xcav.end_date_active            xcav_end_date_active,
                xcasv.start_date_active         xcasv_start_date_active,
                xcasv.end_date_active           xcasv_end_date_active
           FROM
                 xxcmn_delivery_lt2_v          lt    --�z��L/T�A�h�I���}�X�^�i�q�ɁE���_�j
                ,xxcmn_cust_accounts2_v        xcav
                ,xxcmn_cust_acct_sites2_v      xcasv
           WHERE lt.code_class1                   = :cv_code_class_4 --�R�[�h�敪1�F�q��
           AND   lt.code_class2                   = :cv_code_class_1 --�R�[�h�敪2�F���_
           AND   lt.entering_despatching_code2    = xcav.party_number
           AND   xcasv.base_code                  = xcav.party_number
         )                           lt2    --�z��L/T�A�h�I���}�X�^�i�q�ɁE���_�j
         ,xxcmn_delivery_lt2_v       lt1    --�z��L/T�A�h�I���}�X�^�i�q�ɁE�z����j
         WHERE lt2.code_class1                   = lt1.code_class1(+)
         AND   lt2.entering_despatching_code1    = lt1.entering_despatching_code1(+)
         AND   lt2.party_site_number             = lt1.entering_despatching_code2(+)
         AND   lt1.code_class2(+)                = :cv_code_class_9 --�R�[�h�敪2�F�z����
         ) xdl
       WHERE xottv.order_category_code   =  :cv_order_category_code
                                -- �󒍃^�C�v.�󒍃J�e�S�����u�󒍁v����
       AND   xottv.shipping_shikyu_class =  :cv_shipping_shikyu_class
                                -- �󒍃^�C�v.�o�׎x���敪���u�o�׈˗��v����
       AND   xoha.order_type_id          =  xottv.transaction_type_id
                                -- �󒍃w�b�_�A�h�I��.�󒍃^�C�vID���󒍃^�C�v.����^�C�vID����
       AND   xoha.req_status             =  :gv_status_02';
                                -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u02:���_�m��v����
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
    cv_rewhere                     CONSTANT VARCHAR2(32000) :=
     ' WHERE xottv.order_category_code   =  :cv_order_category_code
                                  -- �󒍃^�C�v.�󒍃J�e�S�����u�󒍁v����
         AND   xottv.shipping_shikyu_class =  :cv_shipping_shikyu_class
                                  -- �󒍃^�C�v.�o�׎x���敪���u�o�׈˗��v����
         AND   xoha.order_type_id          =  xottv.transaction_type_id
                                  -- �󒍃w�b�_�A�h�I��.�󒍃^�C�vID���󒍃^�C�v.����^�C�vID����
         AND   xoha.req_status             =  :gv_status_02
                                  -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u02:���_�m��v����
       AND   (1 = :ln_tightening_prog_id_nullflg -- �t���O��0�Ȃ���߃R���J�����gID�������ɒǉ�����
              OR xtc.concurrent_id       = :in_tightening_program_id)
                                -- �o�׈˗����ߊǗ��i�A�h�I���j.�R���J�����gID
                                -- ���p�����[�^.���߃R���J�����gID����
       AND   xtc.order_type_id           = DECODE(xtc.order_type_id
                                                ,:gn_m999,:gn_m999
                                                         , xoha.order_type_id)
                                -- �o�׈˗����ߊǗ��i�A�h�I���j.�󒍃^�C�vID
                                -- ���󒍃w�b�_�A�h�I��. �󒍃^�C�vID����
       AND   xtc.deliver_from            = DECODE(xtc.deliver_from
                                              ,:gv_ALL,:gv_ALL
                                                      , xoha.deliver_from)
                                -- �o�׈˗����ߊǗ��i�A�h�I���j.�o�׌��ۊǏꏊ
                                -- ���󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ����
       AND   xtc.schedule_ship_date      = xoha.schedule_ship_date
                                -- �o�׈˗����ߊǗ��i�A�h�I���j.�o�ח\���
                                -- ���󒍃w�b�_�A�h�I��.�o�ח\�������
       AND   xtc.prod_class              = xoha.prod_class
                                -- �o�׈˗����ߊǗ��i�A�h�I���j.���i�敪
                                -- ���󒍃w�b�_�A�h�I��.���i�敪����
       AND   xtc.sales_branch           = DECODE(xtc.sales_branch
                                              ,:gv_ALL,:gv_ALL
                                              ,xoha.head_sales_branch)
                                -- �o�׈˗����ߊǗ��i�A�h�I���j.���_
                                -- ���󒍃w�b�_�A�h�I��.�Ǌ����_����
       AND   xtc.sales_branch_category   = DECODE(xtc.sales_branch_category
                                              ,:gv_ALL,:gv_ALL ,
                                              DECODE(xtc.prod_class
                                                   , :cv_prod_class_2, xcav.drink_base_category
                                                   , :cv_prod_class_1, xcav.leaf_base_category))';
                                -- �o�׈˗����ߊǗ��i�A�h�I���j.���_�J�e�S��
                                -- ���ڋq�}�X�^.���_�J�e�S������
--
    cv_where                       CONSTANT VARCHAR2(32000) :=
     ' WHERE xottv.order_category_code   =  :cv_order_category_code
                                  -- �󒍃^�C�v.�󒍃J�e�S�����u�󒍁v����
       AND   xottv.shipping_shikyu_class =  :cv_shipping_shikyu_class
                                  -- �󒍃^�C�v.�o�׎x���敪���u�o�׈˗��v����
       AND   xoha.order_type_id          =  xottv.transaction_type_id
                                  -- �󒍃w�b�_�A�h�I��.�󒍃^�C�vID���󒍃^�C�v.����^�C�vID����
       AND   xoha.req_status             =  :gv_status_02
                                  -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u02:���_�m��v����
       AND  ((1 = :ln_order_type_id_nullflg) -- �t���O��0�Ȃ�o�׌��������ɒǉ�����
              OR  (xoha.order_type_id     =  :in_order_type_id))
                                -- �󒍃w�b�_�A�h�I��.�o�Ɍ`��ID���p�����[�^.�o�Ɍ`��ID����
       AND  ((1 = :ln_deliver_from_nullflg) -- �t���O��0�Ȃ�o�׌��������ɒǉ�����
              OR (xoha.deliver_from       = :iv_deliver_from))
                                -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ���p�����[�^.�o�׌�����
       AND  ((1 = :ln_request_no_nullflg) -- �t���O��0�Ȃ�˗�No�������ɒǉ�����
              OR (xoha.request_no         = :iv_request_no))
                                -- �󒍃w�b�_�A�h�I��.�˗�No���p�����[�^.�˗�No����
       AND  ((1 = :ln_schedule_ship_date_nullflg) -- �t���O��0�Ȃ�o�ɓ��������ɒǉ�����
              OR (xoha.schedule_ship_date = :id_schedule_ship_date))
                                -- �󒍃w�b�_�A�h�I��.�o�ח\������p�����[�^.�o�ɓ�����
       AND  ((1 = :ln_prod_class_nullflg) -- �t���O��0�Ȃ�˗�No�������ɒǉ�����
              OR (xoha.prod_class         = :iv_prod_class))';
                                -- �󒍃w�b�_�A�h�I��.���i�敪���p�����[�^.���i�敪 ����
--
-- 2008/12/17 mod start ver1.13 M_Uehara
    cv_main_sql2                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.party_number            = xoha.head_sales_branch
                   -- �p�[�e�B�}�X�^(�Ǌ����_)�D�g�D�ԍ����󒍃w�b�_�A�h�I���D�Ǌ����_����
       AND   xcav.start_date_active       <= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                   -- �p�[�e�B�A�h�I���}�X�^(�Ǌ����_)�D�K�p�J�n�����p�����[�^. �o�ɓ�����
       AND   xcav.end_date_active         >= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                -- �p�[�e�B�A�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
       AND   xcav.customer_class_code     = :cv_customer_class_code_1
                                -- �ڋq�}�X�^�D�ڋq�敪=1����
       AND  ((1 = :ln_drink_base_category_flg)
                                    -- �t���O��0�Ȃ�h�����N���_�J�e�S���������ɒǉ�����
              OR (xcav.drink_base_category         = :iv_sales_base_category))
                                -- �ڋq�}�X�^�D�h�����N���_�J�e�S�����p�����[�^�D���_�J�e�S��
       AND  ((1 = :ln_leaf_base_category_flg)
                                    -- �t���O��0�Ȃ烊�[�t���_�J�e�S���������ɒǉ�����
              OR (xcav.leaf_base_category = :iv_sales_base_category))
                                -- �ڋq�}�X�^�D���[�t���_�J�e�S�����p�����[�^�D���_�J�e�S��
       AND   xdl.entering_despatching_code1  = xoha.deliver_from
                                                           -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
       AND   xdl.entering_despatching_code2  = xoha.deliver_to
                                                           -- �󒍃w�b�_�A�h�I��.�z����
       AND   xcasv.base_code                  = xcav.party_number
       AND   xoha.deliver_to_id             =  xcasv.party_site_id
       AND   xcasv.start_date_active         <= xoha.schedule_ship_date
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND  (xcasv.end_date_active           IS NULL
         OR  xcasv.end_date_active           >= xoha.schedule_ship_date)'
       ;                                                   -- �󒍃w�b�_�A�h�I��.�o�ח\���
     cv_lead_time_w1                   CONSTANT VARCHAR2(32000)
     :=    ' AND  receipt_change_lead_time_day =  :in_lead_time_day';
                                     -- �������ύXLT�i�q�ɁE�z����j
                                     -- �������ύXLT�i�q�ɁE���_�j
--
     cv_lead_time_w2                   CONSTANT VARCHAR2(32000)
     :=    ' AND  drink_lead_time_day =  :in_lead_time_day';
                                     --�h�����N���Y����LT�i�q�ɁE�z����j
                                     --�h�����N���Y����LT�i�q�ɁE���_�j
--
     cv_lead_time_w3                   CONSTANT VARCHAR2(32000)
     :=    ' AND  leaf_lead_time_day =  :in_lead_time_day';
                                     -- ���[�t���Y����LT�i�q�ɁE�z����
                                     -- ���[�t���Y����LT�i�q�ɁE���_�j
     cv_main_sql3                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.account_status            =  :gv_status_A--�i�L���j
       AND   xcasv.cust_acct_site_status    =  :gv_status_A--�i�L���j
       AND   xcasv.cust_site_uses_status    =  :gv_status_A--�i�L���j
       AND   xottv.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND  (xottv.end_date_active          IS NULL
       OR    xottv.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)) '  ;
--
     cv_union                       CONSTANT VARCHAR2(32000) :=
     ' UNION '
     ;
    cv_main_sql4                    CONSTANT VARCHAR2(32000) :=
     '   -- �z��LT�i�q�ɁE���_�j�Ŏ擾
         SELECT
           xoha.tightening_program_id tightening_program_id
                                         -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.���߃R���J�����gID
         , xoha.order_type_id         order_type_id
                                         -- �󒍃^�C�vID - �󒍃w�b�_�A�h�I��.�󒍃^�C�vID
         , CASE xottv.transaction_type_id -- �󒍃^�C�v
             WHEN :ln_transaction_type_id THEN
                  -- ����ύX
                  xdl.receipt_change_lead_time_day  -- �������ύXLT�i�q�ɁE���_�j
             ELSE
                  -- ����ύX�ȊO
              DECODE(xoha.prod_class,:cv_prod_class_2,  -- �h�����N���Y����LT
                     xdl.drink_lead_time_day     --�h�����N���Y����LT�i�q�ɁE���_�j
                                     ,:cv_prod_class_1,  -- ���[�t���Y����LT
                      xdl.leaf_lead_time_day       -- ���[�t���Y����LT�i�q�ɁE���_�j
                     )
           END                        lead_time_day -- ���[�h�^�C��
         , xoha.schedule_ship_date    schedule_ship_date
                                                        -- �o�ɓ� - �󒍃w�b�_�A�h�I��.�o�ח\���
         , xoha.schedule_arrival_date schedule_arrival_date
                                                        -- ���� - �󒍃w�b�_�A�h�I��.���ח\���
         , xoha.deliver_to            deliver_to
                                                        -- �z����R�[�h - �󒍃w�b�_�A�h�I��.�o�א�
         , xoha.deliver_from          deliver_from
                                        -- �o�׌��ۊǏꏊ�R�[�h - �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
         , xoha.prod_class            prod_class
                                                        -- ���i�敪 - �󒍃w�b�_�A�h�I��.���i�敪
         , xoha.request_no            request_no
                                                        -- �˗�No - �󒍃w�b�_�A�h�I��.�˗�No
         , xoha.order_header_id       order_header_id   -- �󒍃w�b�_�A�h�I��ID
         FROM
           xxwsh_oe_transaction_types2_v xottv    --�@�󒍃^�C�v���VIEW2
          ,xxwsh_order_headers_all       xoha     --�A�󒍃w�b�_�A�h�I��
          ,xxcmn_cust_accounts2_v        xcav
          ,(SELECT DISTINCT
                lt.code_class1                  code_class1,
                                                              --�R�[�h�敪1�i�q�ɁE���_�j
                lt.entering_despatching_code1   entering_despatching_code1,
                                                              --���o�ɏꏊ�R�[�h�P�i�q�ɁE���_�j
                lt.code_class2                  code_class2,
                                                              --�R�[�h�敪2�i�q�ɁE���_�j
                lt.entering_despatching_code2   entering_despatching_code2,
                                                              --���o�ɏꏊ�R�[�h2�i�q�ɁE���_�j
                lt.drink_lead_time_day          drink_lead_time_day,
                                                              --�h�����N���Y����LT�i�q�ɁE���_�j
                lt.leaf_lead_time_day           leaf_lead_time_day,
                                                              --���[�t���Y����LT�i�q�ɁE���_�j
                lt.receipt_change_lead_time_day receipt_change_lead_time_day,
                                                              --�������ύXLT�i�q�ɁE���_�j
                lt.lt_start_date_active         lt_start_date_active,
                lt.lt_end_date_active           lt_end_date_active
           FROM
                 xxcmn_delivery_lt2_v          lt    --�z��L/T�A�h�I���}�X�^�i�q�ɁE���_�j
           WHERE lt.code_class1                   = :cv_code_class_4 --�R�[�h�敪1�F�q��
           AND   lt.code_class2                   = :cv_code_class_1 --�R�[�h�敪2�F���_
         )                           xdl    --�z��L/T�A�h�I���}�X�^�i�q�ɁE���_�j
       ';
    cv_main_sql5                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.party_number            = xoha.head_sales_branch
                   -- �p�[�e�B�}�X�^(�Ǌ����_)�D�g�D�ԍ����󒍃w�b�_�A�h�I���D�Ǌ����_����
       AND   xcav.start_date_active       <= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                   -- �p�[�e�B�A�h�I���}�X�^(�Ǌ����_)�D�K�p�J�n�����p�����[�^. �o�ɓ�����
       AND   xcav.end_date_active         >= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                -- �p�[�e�B�A�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
       AND   xcav.customer_class_code     = :cv_customer_class_code_1
                                -- �ڋq�}�X�^�D�ڋq�敪=1����
       AND  ((1 = :ln_drink_base_category_flg)
                                    -- �t���O��0�Ȃ�h�����N���_�J�e�S���������ɒǉ�����
              OR (xcav.drink_base_category         = :iv_sales_base_category))
                                -- �ڋq�}�X�^�D�h�����N���_�J�e�S�����p�����[�^�D���_�J�e�S��
       AND  ((1 = :ln_leaf_base_category_flg)
                                    -- �t���O��0�Ȃ烊�[�t���_�J�e�S���������ɒǉ�����
              OR (xcav.leaf_base_category = :iv_sales_base_category))
                                -- �ڋq�}�X�^�D���[�t���_�J�e�S�����p�����[�^�D���_�J�e�S��
       AND   xdl.entering_despatching_code1  = xoha.deliver_from
                                                           -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
       AND   xdl.entering_despatching_code2  = xoha.head_sales_branch
                                                           -- �󒍃w�b�_�A�h�I��.���_
       ';
     cv_main_sql6                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.account_status            =  :gv_status_A--�i�L���j
       AND   xottv.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND  (xottv.end_date_active          IS NULL
       OR    xottv.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date))
          ---------------------------------------------------------------------------------------------
          -- �z��L/T�A�h�I���i�z����œo�^����Ă��Ȃ����Ɓj
          ---------------------------------------------------------------------------------------------
       AND NOT EXISTS ( SELECT  1
                        FROM    xxcmn_delivery_lt2_v  xdl2v       -- �z��L/T�A�h�I��
                        WHERE   xdl2v.code_class1                 = :cv_deliver_from_4
                        AND     xdl2v.entering_despatching_code1  = xoha.deliver_from
                        AND     xdl2v.code_class2                 = :cv_deliver_to_9
                        AND     xdl2v.entering_despatching_code2  = xoha.deliver_to
                        AND     NVL(xoha.shipped_date,xoha.schedule_ship_date) BETWEEN xdl2v.lt_start_date_active 
                        AND NVL( xdl2v.lt_end_date_active, NVL(xoha.shipped_date,xoha.schedule_ship_date) )
                     )
        )';
/** 
           cv_main_sql3                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.party_number            = xoha.head_sales_branch
                   -- �p�[�e�B�}�X�^(�Ǌ����_)�D�g�D�ԍ����󒍃w�b�_�A�h�I���D�Ǌ����_����
       AND   xcav.start_date_active       <= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                   -- �p�[�e�B�A�h�I���}�X�^(�Ǌ����_)�D�K�p�J�n�����p�����[�^. �o�ɓ�����
       AND   xcav.end_date_active         >= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                -- �p�[�e�B�A�h�I���}�X�^.�K�p�I�������p�����[�^. �o�ɓ�����
       AND   xcav.customer_class_code     = :cv_customer_class_code_1
                                -- �ڋq�}�X�^�D�ڋq�敪=1����
       AND  ((1 = :ln_drink_base_category_flg)
                                    -- �t���O��0�Ȃ�h�����N���_�J�e�S���������ɒǉ�����
              OR (xcav.drink_base_category         = :iv_sales_base_category))
                                -- �ڋq�}�X�^�D�h�����N���_�J�e�S�����p�����[�^�D���_�J�e�S��
       AND  ((1 = :ln_leaf_base_category_flg)
                                    -- �t���O��0�Ȃ烊�[�t���_�J�e�S���������ɒǉ�����
              OR (xcav.leaf_base_category = :iv_sales_base_category))
                                -- �ڋq�}�X�^�D���[�t���_�J�e�S�����p�����[�^�D���_�J�e�S��
       AND   xdl.lt2_entering_despatching_code1  = xoha.deliver_from
                                                           -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
       AND  (xdl.lt1_entering_despatching_code2  IS NULL
         OR  xdl.lt1_entering_despatching_code2  = xoha.deliver_to)
                                                           -- �󒍃w�b�_�A�h�I��.�o�א�
       AND   xdl.lt2_entering_despatching_code2  = xoha.head_sales_branch
                                                           -- �󒍃w�b�_�A�h�I��.�Ǌ����_
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND  (xdl.lt1_start_date_active           IS NULL
         OR  xdl.lt1_start_date_active           <= xoha.schedule_ship_date)
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND  (xdl.lt1_end_date_active             IS NULL
         OR  xdl.lt1_end_date_active             >= xoha.schedule_ship_date)
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND   xdl.lt2_start_date_active           <= xoha.schedule_ship_date
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND  (xdl.lt2_end_date_active             IS NULL
         OR  xdl.lt2_end_date_active             >= xoha.schedule_ship_date)
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND   xdl.xcav_start_date_active          <= xoha.schedule_ship_date
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND  (xdl.xcav_end_date_active            IS NULL
         OR  xdl.xcav_end_date_active            >= xoha.schedule_ship_date)
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND   xdl.xcasv_start_date_active         <= xoha.schedule_ship_date
                                                           -- �󒍃w�b�_�A�h�I��.�o�ח\���
       AND  (xdl.xcasv_end_date_active           IS NULL
         OR  xdl.xcasv_end_date_active           >= xoha.schedule_ship_date)'
       ;                                                   -- �󒍃w�b�_�A�h�I��.�o�ח\���
--
     cv_lead_time_w1                   CONSTANT VARCHAR2(32000)
     :=    ' AND  NVL(xdl.lt1_rcpt_cng_lead_time_day
                     ,xdl.lt2_rcpt_cng_lead_time_day) =  :in_lead_time_day';
                                     -- �������ύXLT�i�q�ɁE�z����j
                                     -- �������ύXLT�i�q�ɁE���_�j
--
     cv_lead_time_w2                   CONSTANT VARCHAR2(32000)
     :=    ' AND  NVL(xdl.lt1_drink_lead_time_day
                    , xdl.lt2_drink_lead_time_day) =  :in_lead_time_day';
                                     --�h�����N���Y����LT�i�q�ɁE�z����j
                                     --�h�����N���Y����LT�i�q�ɁE���_�j
--
     cv_lead_time_w3                   CONSTANT VARCHAR2(32000)
     :=    ' AND  NVL(xdl.lt1_leaf_lead_time_day
                    , xdl.lt2_leaf_lead_time_day) =  :in_lead_time_day';
                                     -- ���[�t���Y����LT�i�q�ɁE�z����
                                     -- ���[�t���Y����LT�i�q�ɁE���_�j
--
    cv_main_sql4                   CONSTANT VARCHAR2(32000) :=
     ' AND   xoha.deliver_to_id             =  xcasv2.party_site_id
       AND   xcasv2.party_id                =  xcav2.party_id
       AND   xcav2.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcav2.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcasv2.start_date_active       <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcasv2.end_date_active         >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcav.account_status            =  :gv_status_A--�i�L���j
       AND   xcav2.account_status           =  :gv_status_A--�i�L���j
       AND   xcasv2.cust_acct_site_status   =  :gv_status_A--�i�L���j
       AND   xcasv2.cust_site_uses_status   =  :gv_status_A--�i�L���j
       AND   xottv.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND  (xottv.end_date_active          IS NULL
       OR    xottv.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date))
--2008/12/07 D.Sugahara Mod Start
         FOR UPDATE OF xoha.req_status SKIP LOCKED '
--       FOR UPDATE OF xoha.req_status NOWAIT'
--2008/12/07 D.Sugahara Mod End
      ;
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
    -- *** ���[�J���E�J�[�\�� ***
--
    TYPE ref_cursor   IS REF CURSOR ;             -- ������ߗp
    upd_status_cur     ref_cursor ;
--
    TYPE reref_cursor   IS REF CURSOR ;           -- �Ē��ߗp
    reupd_status_cur     reref_cursor ;
    -- *** ���[�J���E���R�[�h ***
--
--
    TYPE ret_value  IS RECORD
      (
        tightening_program_id          xxwsh_order_headers_all.tightening_program_id%TYPE  -- ���߃R���J�����gID
       ,order_type_id                  xxwsh_order_headers_all.order_type_id%TYPE          -- �󒍃^�C�vID
       ,lead_time_day                  NUMBER                                              -- ����ύXLT
       ,schedule_ship_date             xxwsh_order_headers_all.schedule_ship_date%TYPE     -- �o�ח\���
       ,schedule_arrival_date          xxwsh_order_headers_all.schedule_ship_date%TYPE     -- ���ח\���
       ,deliver_to                     xxwsh_order_headers_all.deliver_to%TYPE             -- �o�א�
       ,deliver_from                   xxwsh_order_headers_all.deliver_from%TYPE           -- �o�׌��ۊǏꏊ
       ,prod_class                     xxwsh_order_headers_all.prod_class%TYPE             -- ���i�敪
       ,request_no                     xxwsh_order_headers_all.request_no%TYPE             -- �˗�No
       ,order_header_id                xxwsh_order_headers_all.order_header_id%TYPE        -- �󒍃w�b�_�A�h�I��ID
      );
    lr_u_rec    ret_value ;
--
    -- ===============================
    -- ���[�U�[��`��O
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--
    -- ������
    gv_callfrom_flg := iv_callfrom_flg;
    lv_err_message := NULL;
    lv_retcode := '0';
    ln_stschk_error_flg := 0;            -- 2008/12/17 Add V1.13
--
    -- ���ʍX�V���̎擾
    gn_user_id         := FND_GLOBAL.USER_ID;        -- ���O�C�����Ă��郆�[�U�[��ID�擾
    gn_login_id        := FND_GLOBAL.LOGIN_ID;       -- �ŏI�X�V���O�C��
    gn_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- �v��ID
    gn_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- �ݶ��āE��۸��сE���ع����ID
    gn_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- �R���J�����g�E�v���O����ID
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- **************************************************
    -- *** �p�����[�^�`�F�b�N(E-1)
    -- **************************************************
--
--  �K�{�`�F�b�N
--
    -- �u���߃X�e�[�^�X�`�F�b�N�敪�v�`�F�b�N
    IF (iv_tightening_status_chk_class IS NULL) THEN
      -- ���߃X�e�[�^�X�`�F�b�N�敪��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_null,
                               gv_cnst_tkn_para,
                               gv_msg_null_06) || gv_line_feed;
    END IF;
--
    -- �u�ďo���t���O�v�`�F�b�N
    IF (iv_callfrom_flg IS NULL) THEN
      -- �ďo���t���O��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_null,
                               gv_cnst_tkn_para,
                               gv_msg_null_03) || gv_line_feed;
    END IF;
--
--  �Ó����`�F�b�N
--
    -- �u���ߏ����敪�v�`�F�b�N
    IF ((NVL(iv_tighten_class,cv_tighten_class_1) <> cv_tighten_class_1)
    AND (NVL(iv_tighten_class,cv_tighten_class_1) <> cv_tighten_class_2)) THEN
      -- ���ߏ����敪��1:����A2:�ĈȊO�̃`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_prop,
                               gv_cnst_tkn_para,
                               gv_msg_null_02) || gv_line_feed;
    END IF;
--
    -- �u���߃X�e�[�^�X�`�F�b�N�敪�v�`�F�b�N
    IF ((iv_tightening_status_chk_class <> cv_tightening_status_chk_cla_1)
    AND (iv_tightening_status_chk_class <> cv_tightening_status_chk_cla_2)) THEN
      -- ���߃X�e�[�^�X�`�F�b�N�敪��1�A2�ȊO�̃`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_prop,
                               gv_cnst_tkn_para,
                               gv_msg_null_06) || gv_line_feed;
    END IF;
--
    -- �ďo���t���O����ʂ̏ꍇ�A����R�[�h�敪�F'Z'��o�^����B
    IF (iv_callfrom_flg = cv_callfrom_flg_2) THEN
      gv_base_record_class := cv_base_record_class_Z;
    END IF;
    -- �u����R�[�h�敪�v���o�^����Ă���ꍇ
    IF (iv_base_record_class IS NOT NULL) THEN
      -- �u����R�[�h�敪�v�`�F�b�N
      IF ((iv_base_record_class <> cv_base_record_class_Y)
      AND (iv_base_record_class <> cv_base_record_class_N)
      AND (iv_base_record_class <> cv_base_record_class_Z)) THEN
        -- ����R�[�h�敪��NULL�`�F�b�N���s���܂�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_prop,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_01) || gv_line_feed;
      ELSE
        --�O���[�o���ϐ��Ɋ���R�[�h�敪���Z�b�g
        gv_base_record_class := iv_base_record_class;
      END IF;
    END IF;
--
    -- �u�o�ɓ��v���o�^����Ă���ꍇ
    IF (id_schedule_ship_date IS NOT NULL) THEN
      -- �u�o�ɓ��v�`���`�F�b�N
      IF (gn_status_error
          = xxcmn_common_pkg.check_param_date_yyyymmdd(id_schedule_ship_date)) THEN
        -- �o�ɓ���YYYY/MM/DD�łȂ��ꍇ�A�G���[��Ԃ�
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_fomt,
                                 'DATE',
                                 gv_msg_null_08) || gv_line_feed;
      END IF;
    END IF;
--
    -- �u�ďo���t���O�v�`�F�b�N
    IF ((iv_callfrom_flg <> cv_callfrom_flg_1)
    AND (iv_callfrom_flg <> cv_callfrom_flg_2)) THEN
      -- �ďo���t���O��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_prop,
                               gv_cnst_tkn_para,
                               gv_msg_null_03) || gv_line_feed;
    END IF;
--
    -- �u�ďo���t���O�v�u�˗�No�v�Ó��`�F�b�N
    IF ((iv_callfrom_flg = cv_callfrom_flg_2)
    AND (iv_request_no IS NULL)) THEN
      -- �ďo���t���O��2:��ʂ̎��A�˗�No��NULL�`�F�b�N���s���܂�
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_null,
                               gv_cnst_tkn_para,
                               gv_msg_null_05) || gv_line_feed;
    END IF;
--
--
    IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_1)
    AND (iv_callfrom_flg = cv_callfrom_flg_1) THEN
      -- ���ߏ����敪��1:����̏ꍇ���ďo���敪��1�F�R���J�����g�̏ꍇ�`�F�b�N���s���܂�
--
      -- �u�o�Ɍ`��ID�v�u���i�敪�v�`�F�b�N
      IF ((in_order_type_id IS NULL)
      AND (iv_prod_class = cv_prod_class_1)) THEN
        -- �o�Ɍ`��ID�������͂̏ꍇ����
        -- �p�����[�^.���i�敪�����[�t�̏ꍇ
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_07) || gv_line_feed;
      END IF;
--
      -- ���������p�̕ϐ��u���_�J�e�S���v��ݒ�
      -- ���̓p�����[�^�u���_�J�e�S���v��'0'ALL�̏ꍇ�A������'ALL'���Z�b�g
      IF (iv_sales_base_category = gv_sales_base_category_0) THEN
        gv_sales_base_category := gv_ALL;
      -- ���̓p�����[�^�u���_�J�e�S���v��'0'ALL�ꍇ�A���̓p�����[�^�u���_�J�e�S���v���Z�b�g
      ELSE
        gv_sales_base_category := iv_sales_base_category;
      END IF;
--
      -- �u���Y����LT�v�`�F�b�N
      IF (in_lead_time_day IS NULL) THEN
        -- �p�����[�^���Y����LT�������͂̏ꍇ
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_10) || gv_line_feed;
      END IF;
--
    ELSIF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_2) THEN
      -- ���ߏ����敪��2:�Ē��߂̏ꍇ�`�F�b�N���s���܂�
--
      -- �u���߃R���J�����gID�v�`�F�b�N
      IF (in_tightening_program_id IS NULL) THEN
        -- �p�����[�^���߃R���J�����gID�������͂̏ꍇ
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_11) || gv_line_feed;
      END IF;
--
      -- �u�o�Ɍ`��ID�v�u���i�敪�v�`�F�b�N
      IF ((in_order_type_id IS NULL)
      AND (iv_prod_class = cv_prod_class_1)) THEN
        -- �o�Ɍ`��ID�������͂̏ꍇ����
        -- �p�����[�^.���i�敪�����[�t�̏ꍇ
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_07) || gv_line_feed;
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
      RAISE global_api_expt;
    END IF;
--
--
    -- �p�����[�^.�o�Ɍ`��ID NULL�`�F�b�N
    IF  (in_order_type_id IS NULL) THEN
      -- �o�Ɍ`��ID��NULL�̏ꍇ
      ln_order_type_id_nullflg := 1;
    ELSE
      ln_order_type_id_nullflg := 0;
    END IF;
--
    -- �p�����[�^.�o�Ɍ� NULL�`�F�b�N
    IF  (iv_deliver_from IS NULL) THEN
      -- �o�Ɍ���NULL�̏ꍇ
      ln_deliver_from_nullflg := 1;
    ELSE
      ln_deliver_from_nullflg := 0;
    END IF;
--
    -- �p�����[�^.�˗�No NULL�`�F�b�N
    IF  (iv_request_no IS NULL) THEN
      -- �z����ID��NULL�̏ꍇ
      ln_request_no_nullflg := 1;
    ELSE
      ln_request_no_nullflg := 0;
    END IF;
--
    -- �p�����[�^.�o�ɓ� NULL�`�F�b�N
    IF  (id_schedule_ship_date IS NULL) THEN
      -- �o�ɓ���NULL�̏ꍇ
      ln_schedule_ship_date_nullflg := 1;
    ELSE
      ln_schedule_ship_date_nullflg := 0;
    END IF;
--
    -- �p�����[�^.���i�敪
    IF (iv_prod_class IS NULL) THEN
      -- ���i�敪��NULL�̏ꍇ
      ln_prod_class_nullflg := 1;
    ELSE
      ln_prod_class_nullflg := 0;
    END IF;
--
    -- �p�����[�^.���i�敪
    IF  ((iv_prod_class IS NULL)
    OR   (iv_prod_class <> cv_prod_class_2)
    OR  (gv_sales_base_category IS NULL)
    OR  (gv_sales_base_category = gv_ALL)) THEN
      -- ���i�敪��NULL�܂���2�ȊO�A�܂��͋��_�J�e�S����NULL�܂���'ALL'�̏ꍇ
      ln_drink_base_category_flg := 1;
    ELSE
      ln_drink_base_category_flg := 0;
    END IF;
--
    -- �p�����[�^.���i�敪
    IF ((iv_prod_class IS NULL)
    OR  (iv_prod_class <> cv_prod_class_1)
    OR  (gv_sales_base_category IS NULL)
    OR  (gv_sales_base_category = gv_ALL)) THEN
      -- ���i�敪��NULL�܂���2�ȊO�A�܂��͋��_�J�e�S����NULL�܂���'ALL'�̏ꍇ
      ln_leaf_base_category_flg := 1;
    ELSE
      ln_leaf_base_category_flg := 0;
    END IF;
--
    -- �p�����[�^.���߃R���J�����gID
    IF (in_tightening_program_id IS NULL) THEN
      -- ���߃R���J�����gID��NULL�̏ꍇ
      ln_tightening_prog_id_nullflg := 1;
    ELSE
      ln_tightening_prog_id_nullflg := 0;
    END IF;
--
--
    ld_sysdate := TRUNC(SYSDATE); -- �V�X�e�����t�̎擾
--
    IF (id_schedule_ship_date IS NULL) THEN
      -- �V�X�e�����t���Z�b�g
      ld_schedule_ship_date := ld_sysdate;
    ELSE
      -- �o�ɓ����Z�b�g
      ld_schedule_ship_date := id_schedule_ship_date;
    END IF;
--
    -- ===============================
    -- �֘A�f�[�^�擾
    -- ===============================
    init_proc(
      id_schedule_ship_date,          -- �o�ɓ�
      ln_transaction_type_id,         -- �^�C�vID
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �^�C�vID = �o�Ɍ`��ID
    IF (ln_transaction_type_id = in_order_type_id) THEN
      -- ����ύX
      lv_lead_time_w := cv_lead_time_w1;
    ELSE
      -- ����ύX�ȊO
--
      IF (cv_prod_class_2 = iv_prod_class) THEN
        -- �h�����N���Y����LT
        lv_lead_time_w := cv_lead_time_w2;
      ELSIF (cv_prod_class_1 = iv_prod_class) THEN
        -- ���[�t���Y����LT
        lv_lead_time_w := cv_lead_time_w3;
      END IF;
    END IF;
--
    IF (iv_instruction_dept IS NULL) THEN
      -- �p�����[�^�����������͂̏ꍇ�A�w�������擾����
      get_party_number(ld_schedule_ship_date, -- �o�ɓ��܂��̓V�X�e�����t
                       gv_party_number,       -- �g�D�ԍ�
                       lv_user_name,          -- ���[�U�[��
                       lv_retcode,            -- ���^�[���R�[�h
                       lv_errbuf,             -- �G���[���b�Z�[�W�R�[�h
                       lv_errmsg);            -- �G���[���b�Z�[�W
--
      -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
     IF ((lv_retcode = gn_status_error)
     OR  (gv_party_number IS NULL)) THEN
       -- ���O�C�����[�U�w��������NULL�܂��͑Ώۃf�[�^�����̏ꍇ
       lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                             gv_cnst_msg_208,
                                             'USER_NAME',
                                             lv_user_name);
       RAISE global_api_expt;
     END IF;
--
   ELSE
     gv_party_number := iv_instruction_dept;
   END IF;
--
--  �X�V�pPL/SQL�\������
    gt_header_id_upd_tab.DELETE; -- �󒍃w�b�_�A�h�I��ID
--
    -- **************************************************
    -- *** �o�׈˗����擾(E-2)
    -- **************************************************
    -- �ďo���t���O��2:��ʂ̏ꍇ
    IF (iv_callfrom_flg = cv_callfrom_flg_2) THEN
      lv_sql :=    cv_main_sql;
      -- SQL�̎��s
      OPEN upd_status_cur FOR lv_sql
        USING
          iv_request_no;
    -- �ďo���t���O��1:�R���J�����g�̏ꍇ
    ELSIF (iv_callfrom_flg = cv_callfrom_flg_1) THEN
      IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_1) THEN
        -- ����J�[�\���I�[�v��
--
-- 2008/12/17 mod start ver1.13 M_Uehara
        -- ���ISQL�{�������߂�
        lv_sql :=   cv_main_sql1
                 || cv_where
                 || cv_main_sql2
                 || lv_lead_time_w
                 || cv_main_sql3
                 || cv_union
                 || cv_main_sql4
                 || cv_where
                 || cv_main_sql5
                 || lv_lead_time_w
                 || cv_main_sql6;
--
        -- SQL�̎��s
        OPEN upd_status_cur FOR lv_sql
          USING
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_order_type_id_nullflg,
            in_order_type_id,
            ln_deliver_from_nullflg,
            iv_deliver_from,
            ln_request_no_nullflg,
            iv_request_no,
            ln_schedule_ship_date_nullflg,
            id_schedule_ship_date,
            ln_prod_class_nullflg,
            iv_prod_class,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            in_lead_time_day,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_order_type_id_nullflg,
            in_order_type_id,
            ln_deliver_from_nullflg,
            iv_deliver_from,
            ln_request_no_nullflg,
            iv_request_no,
            ln_schedule_ship_date_nullflg,
            id_schedule_ship_date,
            ln_prod_class_nullflg,
            iv_prod_class,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            in_lead_time_day,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            cv_deliver_from_4,
            cv_deliver_to_9
            ;
--
      ELSE
        -- �Ē��߃J�[�\���I�[�v��
--
        -- ���ISQL�{�������߂�
        lv_sql :=   cv_main_sql1
                 || cv_retable
                 || cv_rewhere
                 || cv_main_sql2
-- 2008/12/23 addd start ver1.14 M_Uehara
                 || lv_lead_time_w
-- 2008/12/23 addd end ver1.14 M_Uehara
                 || cv_main_sql3
                 || cv_union
                 || cv_main_sql4
                 || cv_retable
                 || cv_rewhere
                 || cv_main_sql5
-- 2008/12/23 addd start ver1.14 M_Uehara
                 || lv_lead_time_w
-- 2008/12/23 addd end ver1.14 M_Uehara
                 || cv_main_sql6;
--
        -- SQL�̎��s
        OPEN reupd_status_cur FOR lv_sql
          USING
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_tightening_prog_id_nullflg,
            in_tightening_program_id,
            gn_m999,
            gn_m999,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
-- 2008/12/23 addd start ver1.14 M_Uehara
            in_lead_time_day,
-- 2008/12/23 addd end ver1.14 M_Uehara
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_tightening_prog_id_nullflg,
            in_tightening_program_id,
            gn_m999,
            gn_m999,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
-- 2008/12/23 addd start ver1.14 M_Uehara
            in_lead_time_day,
-- 2008/12/23 addd end ver1.14 M_Uehara
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            cv_deliver_from_4,
            cv_deliver_to_9
            ;
--
/**
        -- ���ISQL�{�������߂�
        lv_sql :=   cv_main_sql1
                 || cv_main_sql2
                 || cv_where
                 || cv_main_sql3
                 || lv_lead_time_w
                 || cv_main_sql4;
--
        -- SQL�̎��s
        OPEN upd_status_cur FOR lv_sql
          USING
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_order_type_id_nullflg,
            in_order_type_id,
            ln_deliver_from_nullflg,
            iv_deliver_from,
            ln_request_no_nullflg,
            iv_request_no,
            ln_schedule_ship_date_nullflg,
            id_schedule_ship_date,
            ln_prod_class_nullflg,
            iv_prod_class,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            in_lead_time_day,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date
            ;
--
      ELSE
        -- �Ē��߃J�[�\���I�[�v��
--
        -- ���ISQL�{�������߂�
        lv_sql :=   cv_main_sql1
                 || cv_retable
                 || cv_main_sql2
                 || cv_rewhere
                 || cv_main_sql3
                 || cv_main_sql4;
--
        -- SQL�̎��s
        OPEN reupd_status_cur FOR lv_sql
          USING
-- 1.6 UPD START
--            cv_order_type_id_04,
            ln_transaction_type_id,
-- 1.6 UPD END
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_tightening_prog_id_nullflg,
            in_tightening_program_id,
            gn_m999,
            gn_m999,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date
            ;
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
      END IF;
    END IF;
--
    -- ========================================
    -- �f�[�^�̃`�F�b�N���s��
    -- ========================================
    <<data_loop>>
    LOOP
--
      -- ���R�[�h�Ǎ�
      IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_1) THEN
        FETCH upd_status_cur INTO lr_u_rec;
        EXIT WHEN upd_status_cur%NOTFOUND;
      ELSE
        FETCH reupd_status_cur INTO lr_u_rec;
        EXIT WHEN reupd_status_cur%NOTFOUND;
      END IF;
--
      -- 2008/12/17 �{�ԏ�Q#81 Add Start ----------------
      ln_lock_error_flg := 0;
      BEGIN
        SELECT xoha.order_header_id
        INTO   ln_order_header_id_lock
        FROM   xxwsh_order_headers_all xoha
        WHERE  xoha.order_header_id = lr_u_rec.order_header_id
        FOR UPDATE NOWAIT;
      EXCEPTION
        WHEN OTHERS THEN
          ln_lock_error_flg := 1;
      END;
--
      IF (ln_lock_error_flg = 0) THEN
      -- 2008/12/17 �{�ԏ�Q#81 Add End ----------------
--
        ln_target_cnt := ln_target_cnt + 1;   --2008/08/05 Add
--
        -- �����������J�E���g
        IF (ln_bfr_order_header_id <> lr_u_rec.order_header_id) THEN
          --ln_target_cnt := ln_target_cnt + 1;   --2008/08/05 Del
          ln_bfr_order_header_id := lr_u_rec.order_header_id;
        END IF;
--
        ln_data_cnt := ln_data_cnt + 1;
--
        IF (iv_tightening_status_chk_class = cv_tightening_status_chk_cla_1) THEN
          -- ���߃X�e�[�^�X�`�F�b�N�敪��1:�`�F�b�N�L��̏ꍇ
--
          -- **************************************************
          -- *** ���߃X�e�[�^�X�`�F�b�N(E-3)
          -- **************************************************
--
          lv_status :=
          xxwsh_common_pkg.check_tightening_status(lr_u_rec.order_type_id,  -- E-2�󒍃^�C�vID
                                                   iv_deliver_from,         -- �p�����[�^.�o�׌�
                                                   iv_sales_base,           -- �p�����[�^.���_
                                                   iv_sales_base_category,  -- �p�����[�^.���_�J�e�S��
                                                   lr_u_rec.lead_time_day,  -- E-2���Y����LT
                                                   lr_u_rec.schedule_ship_date,   -- E-2�o�ɓ�
                                                   lr_u_rec.prod_class);    -- E-2���i�敪
--
          -- ���߃X�e�[�^�X��'2'�܂���'4'�̏ꍇ�̓G���[
          IF ((lv_status = cv_status_2) OR (lv_status = cv_status_4)) THEN
            -- 2008/12/17 Del Start Ver1.13 -----------------------------------
            --lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
            --                                      gv_cnst_msg_204);
            --RAISE global_api_expt;
            -- 2008/12/17 Del Start Ver1.13 -----------------------------------
            -- 2008/12/17 Add Start Ver1.13 -----------------------------------
            FND_FILE.PUT_LINE(FND_FILE.LOG,
              '���߃X�e�[�^�X�`�F�b�N�G���['                  ||
              '/�`�[No:'       || lr_u_rec.request_no         ||
              '/�󒍃^�C�vID:' || lr_u_rec.order_type_id      ||
              '/�o�׌�:'       || iv_deliver_from             ||
              '/���_:'         || iv_sales_base               ||
              '/���_�J�e�S��:' || iv_sales_base_category      ||
              '/���Y����LT:'   || lr_u_rec.lead_time_day      ||
              '/�o�ɓ�:'       || lr_u_rec.schedule_ship_date ||
              '/���i�敪:'     || lr_u_rec.prod_class);
--
            ln_stschk_error_flg := 1;
            -- 2008/12/17 Add End Ver1.13 -------------------------------------
--
          END IF;
        END IF;
--
        -- ���߃X�e�[�^�X�`�F�b�N�敪��0:�`�F�b�N�����̏ꍇ
        IF (iv_callfrom_flg = cv_callfrom_flg_2) THEN
          -- �ďo���t���O 2:��ʂ̏ꍇ��E-4�AE-5�͍s��Ȃ�
          NULL;
        ELSE
--
          -- **************************************************
          -- *** ���[�h�^�C���`�F�b�N(E-4)
          -- **************************************************
--
          -- �o�ɓ��̉ғ����`�F�b�N
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_ship_date, -- E-2�o�ɓ�
                                                       lr_u_rec.deliver_from, -- E-2�o�׌��ۊǏꏊ
                                                       NULL,                  -- �z����R�[�h
                                                       0,                     -- ���[�h�^�C��
                                                       lr_u_rec.prod_class,   -- E-2���i�敪
                                                       ld_oprtn_day);         -- �ғ������t
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
--
          -- �o�ɓ����ғ����łȂ��ꍇ�̓G���[
          ELSIF (ld_oprtn_day <> lr_u_rec.schedule_ship_date) THEN
            -- �o�͍��ڂ̉ғ������t�����̓p�����[�^�œn�������t
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_206,
                                                  'IN_DATE',
                                                  TO_CHAR(lr_u_rec.schedule_ship_date,'YYYY/MM/DD'),
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- �����̉ғ����`�F�b�N
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_arrival_date, -- E-2����
                                                       NULL,                  -- �o�׌��ۊǏꏊ
                                                       lr_u_rec.deliver_to,   -- �z����R�[�h
                                                       0,                     -- ���[�h�^�C��
                                                       lr_u_rec.prod_class,   -- E-2���i�敪
                                                       ld_oprtn_day);         -- �ғ������t
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
--
          -- �������ғ����łȂ��ꍇ�̓G���[
          ELSIF (ld_oprtn_day <> lr_u_rec.schedule_arrival_date) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_206,
                                                  'IN_DATE',
                                                  TO_CHAR(lr_u_rec.schedule_arrival_date,'YYYY/MM/DD'),
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
  -- 2008/11/14 H.Itou Mod Start �����e�X�g�w�E650 ���ד����ғ����łȂ��ꍇ�A�x���i�o�^�͍s���B�j
  --          RAISE global_api_expt;
            ln_warn_cnt := ln_warn_cnt + 1;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            ov_errmsg := gv_msg_warn_01;
  -- 2008/11/14 H.Itou Mod End
          END IF;
--
/* 20081201 D.Sugahara Deleted���b�� Start --���[�h�^�C���G���[��������邽��
          -- ���[�h�^�C���Z�o
          xxwsh_common910_pkg.calc_lead_time(cv_deliver_from_4,     -- 4:�q��
                                             lr_u_rec.deliver_from, -- E-2�o�׌��ۊǏꏊ
                                             cv_deliver_to_9,       -- 9:�z����
                                             lr_u_rec.deliver_to,   -- E-2�z����R�[�h
                                             lr_u_rec.prod_class,   -- E-2���i�敪
                                             lr_u_rec.order_type_id,-- E-2�󒍃^�C�vID
                                             lr_u_rec.schedule_ship_date,-- E-2�o�ɓ�
                                             lv_retcode,            -- ���^�[���R�[�h
                                             lv_errbuf,             -- �G���[���b�Z�[�W�R�[�h
                                             lv_errmsg,             -- �G���[���b�Z�[�W
                                             ln_lead_time,          -- ���Y����LT�^����ύXLT
                                             ln_delivery_lt);       -- �z��LT
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_calc_lead_time_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
-- 2008/11/14 H.Itou Mod Start �����e�X�g�w�E650 ���ד� �| �z�����[�h�^�C���͉ғ������l�����Ȃ��B
--        -- ���[�h�^�C���Ó��`�F�b�N
--        ln_retcode :=
--        xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_arrival_date, -- E-2����
--                                       NULL,                           -- �o�׌��ۊǏꏊ
--                                       lr_u_rec.deliver_to,            -- E-2�z����R�[�h
--                                       ln_delivery_lt,                 -- ���[�h�^�C��
--                                       lr_u_rec.prod_class,            -- E-2���i�敪
--                                       ld_oprtn_day);                  -- �ғ������t
----
--        -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
--        IF (ln_retcode = gn_status_error) THEN
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
--                                                gv_cnst_msg_205,
--                                                gv_cnst_token_api_name,
--                                                cv_get_oprtn_day_api,
--                                                'ERR_MSG',
--                                                '',
--                                                'REQUEST_NO',
--                                                lr_u_rec.request_no);
--          RAISE global_api_expt;
--        END IF;
          -- ���ד� �| �z�����[�h�^�C�����擾
          ld_oprtn_day := lr_u_rec.schedule_arrival_date - ln_delivery_lt;
-- 2008/11/14 H.Itou Mod End
--
          -- E-2�o�ɓ� < �ғ���
          IF (lr_u_rec.schedule_ship_date > ld_oprtn_day) THEN
            -- ���[�h�^�C���𖞂����Ă��Ȃ�
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_207,
                                                  'LT_CLASS',
                                                  cv_get_oprtn_day_lt2,
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- ���[�h�^�C���Ó��`�F�b�N
          ln_retcode :=
          xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_ship_date,    -- E-2�o�ɓ�
                                         NULL,                           -- �o�׌��ۊǏꏊ
                                         lr_u_rec.deliver_to,            -- E-2�z����R�[�h
                                         ln_lead_time,                   -- ���[�h�^�C��
                                         lr_u_rec.prod_class,            -- E-2���i�敪
                                         ld_oprtn_day);                  -- �ғ������t
--
          -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
-- 2008/10/28 H.Itou Mod Start �����e�X�g�w�E141 ���Y����LT�^����ύXLT�`�F�b�N�́A�����o�ׂ̏ꍇ������̂ŁA�ғ����{1 �Ń`�F�b�N���s���B
--        -- �V�X�e�����t > �ғ���
--        IF (ld_sysdate > ld_oprtn_day) THEN
          -- �V�X�e�����t > �ғ��� + 1
          IF (ld_sysdate > ld_oprtn_day + 1) THEN
-- 2008/10/28 H.Itou Mod End
            -- �z�����[�h�^�C�����Ó��łȂ�
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_207,
                                                  'LT_CLASS',
                                                  cv_get_oprtn_day_lt,
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
  */
--
--20081201 D.Sugahara Deleted���b�� End --���[�h�^�C���G���[��������邽��
--
        END IF;
--
        -- **************************************************
        -- *** PL/SQL�\�ւ̑}��(E-6)
        -- **************************************************
--
        gt_header_id_upd_tab(ln_data_cnt) := lr_u_rec.order_header_id; -- �󒍃w�b�_�A�h�I��ID
--
-- 2008/08/05 Mod ��
--      ln_normal_cnt := ln_target_cnt;
        ln_normal_cnt := ln_normal_cnt + 1;
-- 2008/08/05 Mod ��
--
      END IF;    -- 2008/12/17 �{�ԏ�Q#81 Add
--
    END LOOP data_loop;
--
    IF ( upd_status_cur%ISOPEN ) THEN
      CLOSE upd_status_cur;
    END IF;
    IF ( reupd_status_cur%ISOPEN ) THEN
      CLOSE reupd_status_cur;
    END IF;
--
    -- 2008/12/17 Add Start Ver1.13 --------------------------------
    IF (ln_stschk_error_flg = 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,gv_cnst_msg_204);
      RAISE global_api_expt;
    END IF;
    -- 2008/12/17 Add End Ver1.13 -------------------------------------
--
-- 2008/10/10 H.Itou Add Start ���߃��R�[�h�쐬�́A�Ώۃf�[�^�Ȃ��ł��s���B
    -- **************************************************
    -- *** ���ߍς݃��R�[�h�o�^(E-5)
    -- **************************************************
--
    insert_tightening_control(in_order_type_id,       -- �o�Ɍ`��ID
                              iv_deliver_from,        -- �o�׌�
                              iv_sales_base,          -- ���_
                              gv_sales_base_category, -- ���_�J�e�S��
                              in_lead_time_day,       -- ���Y����LT
                              id_schedule_ship_date,  -- �o�ɓ�
                              iv_prod_class,          -- ���i�敪
                              gv_base_record_class,   -- ����R�[�h�敪
                              lv_retcode,             -- ���^�[���R�[�h
                              lv_errbuf,              -- �G���[���b�Z�[�W�R�[�h
                              lv_errmsg);             -- �G���[���b�Z�[�W
--
    -- ���ߍς݃��R�[�h�o�^�������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2008/10/10 H.Itou Add End
--
    IF ( ln_data_cnt = 0 ) THEN
      -- �o�׈˗����Ώۃf�[�^�Ȃ�
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_002);
      -- �x�����Z�b�g
      ln_warn_cnt := 1 ;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
    ELSE
      -- �o�׈˗����Ώۃf�[�^����
--
      -- Del start 2008/06/27 uehara �ďo������ʂł����ߍς݃��R�[�h��o�^����B
--      IF (iv_callfrom_flg = cv_callfrom_flg_1) THEN
        -- �ďo���t���O 1:�R���J�����g
      -- Del end 2008/06/27 uehara
--
-- 2008/10/10 H.Itou Del Start ���߃��R�[�h�쐬�́A�Ώۃf�[�^�Ȃ��ł��s���̂ŁA�ړ�
--      -- **************************************************
--      -- *** ���ߍς݃��R�[�h�o�^(E-5)
--      -- **************************************************
----
--      insert_tightening_control(in_order_type_id,       -- �o�Ɍ`��ID
--                                iv_deliver_from,        -- �o�׌�
--                                iv_sales_base,          -- ���_
--                                gv_sales_base_category, -- ���_�J�e�S��
--                                in_lead_time_day,       -- ���Y����LT
--                                id_schedule_ship_date,  -- �o�ɓ�
--                                iv_prod_class,          -- ���i�敪
--                                gv_base_record_class,   -- ����R�[�h�敪
--                                lv_retcode,             -- ���^�[���R�[�h
--                                lv_errbuf,              -- �G���[���b�Z�[�W�R�[�h
--                                lv_errmsg);             -- �G���[���b�Z�[�W
----
--      -- ���ߍς݃��R�[�h�o�^�������G���[�̏ꍇ
--      IF (lv_retcode = gv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
-- 2008/10/10 H.Itou Del End
      -- Del start 2008/06/27 uehara
--      END IF;
      -- Del end 2008/06/27 uehara
--
      -- **************************************************
      -- *** �X�e�[�^�X�ꊇ�X�V(E-7)
      -- **************************************************
--
      upd_table_batch(
         ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
       , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
       , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �X�e�[�^�X�ꊇ�X�V�������G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (iv_callfrom_flg = cv_callfrom_flg_1) THEN
      -- �ďo���t���O 1:�R���J�����g
--
      IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_2) THEN
        --���ߏ����敪��2:�Ă̏ꍇ
--
      -- **************************************************
      -- *** ���߉������R�[�h�폜 (E-8)
      -- **************************************************
--
        delete_tightening_control(in_tightening_program_id, -- ���߃R���J�����gID
                                  lv_retcode,               -- ���^�[���R�[�h
                                  lv_errbuf,                -- �G���[���b�Z�[�W�R�[�h
                                  lv_errmsg);               -- �G���[���b�Z�[�W
--
        -- �X�e�[�^�X�ꊇ�X�V�������G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** OUT�p�����[�^�Z�b�g(E-9)
    -- **************************************************
--
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    out_log(ln_target_cnt,ln_normal_cnt,0,ln_warn_cnt);
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      IF ( upd_status_cur%ISOPEN ) THEN
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
        CLOSE reupd_status_cur;
      END IF;
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      out_log(0,0,1,0);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( upd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ��
        <<count_loop_upd>>
        LOOP
          FETCH upd_status_cur INTO lr_u_rec;
          EXIT WHEN upd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_upd;
--2008/08/05 Mod ��
--
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ��
        <<count_loop_reupd>>
        LOOP
          FETCH reupd_status_cur INTO lr_u_rec;
          EXIT WHEN reupd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_reupd;
--2008/08/05 Mod ��
--
        CLOSE reupd_status_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--2008/08/05 Mod ��
--      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
      out_log(ln_target_cnt,ln_normal_cnt,1,ln_warn_cnt);
--2008/08/05 Mod ��
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( upd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ��
        <<count_loop_upd>>
        LOOP
          FETCH upd_status_cur INTO lr_u_rec;
          EXIT WHEN upd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_upd;
--2008/08/05 Mod ��
--
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ��
        <<count_loop_reupd>>
        LOOP
          FETCH reupd_status_cur INTO lr_u_rec;
          EXIT WHEN reupd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_reupd;
--2008/08/05 Mod ��
--
        CLOSE reupd_status_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--2008/08/05 Mod ��
--      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
      out_log(ln_target_cnt,ln_normal_cnt,1,ln_warn_cnt);
--2008/08/05 Mod ��
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( upd_status_cur%ISOPEN ) THEN
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
        CLOSE reupd_status_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--2008/08/05 Mod ��
--      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
      out_log(ln_target_cnt,ln_normal_cnt,1,ln_warn_cnt);
--2008/08/05 Mod ��
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ship_tightening;
  --
END xxwsh400004c;
/
