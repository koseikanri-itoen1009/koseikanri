CREATE OR REPLACE PACKAGE BODY xxwip720002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip720002c(body)
 * Description      : �^���A�h�I���}�X�^�捞����
 * MD.050           : �^���v�Z�i�}�X�^�j T_MD050_BPO_720
 * MD.070           : �^���A�h�I���}�X�^�捞�����i72E�jT_MD070_BPO_72E
 * Version          : 1.3
 *
 * Program List
 * ------------------------ ----------------------------------------------------------
 *  Name                     Description
 * ------------------------ ----------------------------------------------------------
 *  get_lock                 �\���b�N�擾����(E-2) 
 *  del_duplication_data     �d���f�[�^���O����(E-3)
 *  get_data_dump            �f�[�^�_���v�擾����
 *  master_data_chk          �}�X�^�f�[�^�`�F�b�N����(E-5)
 *  set_ins_tab              �o�^�pPL/SQL�\����(E-6)
 *  get_ins_data             �V�K�o�^�f�[�^�擾����(E-4)
 *  set_upd_tab              �X�V�pPL/SQL�\����(E-8)
 *  get_upd_data             �X�V�f�[�^�擾����(E-7)
 *  ins_table_batch          �ꊇ�o�^����(E-9)
 *  upd_table_batch          �ꊇ�X�V����(E-10)
 *  upd_end_date_active_all  �K�p�I�����X�V����(E-11)
 *  del_table_data           �f�[�^�폜����(E-12)
 *  put_dump_msg             �f�[�^�_���v�ꊇ�o�͏���
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/09    1.0   Y.Kanami         �V�K�쐬
 *  2008/11/11    1.1   N.Fukuda         �����w�E#589�Ή�
 *  2009/04/03    1.2   A.Shiina         �{��#432�Ή�
 *  2016/06/22    1.3   S.Niki           E_�{�ғ�_13659�Ή�
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxwip720002c';     -- �p�b�P�[�W��
--
  -- ���W���[��������
  gv_xxcmn            CONSTANT VARCHAR2(100) := 'XXCMN';            -- ���W���[�������́FXXCMN ����
  gv_xxwip            CONSTANT VARCHAR2(100) := 'XXWIP';            
                                                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
--
  -- ���b�Z�[�W
  gv_msg_xxwip10004   CONSTANT VARCHAR2(100) := 'APP-XXWIP-10004';  
                                        -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
  gv_msg_xxwip10023   CONSTANT VARCHAR2(100) := 'APP-XXWIP-10023';  
                                        -- ���b�Z�[�W�FAPP-XXWIP-10023 �f�[�^�d���G���[���b�Z�[�W
  gv_msg_xxcmn10001   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001';  
                                        -- ���b�Z�[�W�FAPP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
  gv_msg_xxcmn10002   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  
                                        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
  gv_msg_xxcmn00005   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005';  
                                        -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
  gv_msg_xxcmn00007   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007';  
                                        -- ���b�Z�[�W�FAPP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
--
  -- �g�[�N��
  gv_tkn_table        CONSTANT VARCHAR2(100) := 'TABLE';            -- �g�[�N���FTABLE
  gv_tkn_item         CONSTANT VARCHAR2(100) := 'ITEM';             -- �g�[�N���FITEM
  gv_tkn_key          CONSTANT VARCHAR2(100) := 'KEY';              -- �g�[�N���FKEY
  gv_tkn_ng_profile   CONSTANT VARCHAR2(100) := 'NG_PROFILE';       -- �g�[�N���FNG_PROFILE
--
-- 2009/04/03 v1.2 ADD START
  gv_on               CONSTANT VARCHAR2(1) := '1';                  -- �ύX�t���O�F�ύX����
--
-- 2009/04/03 v1.2 ADD END
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �v��ID�pPL/SQL�\�^
  TYPE request_id_ttype              IS TABLE OF fnd_concurrent_requests.request_id%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �v��ID
--
  -- �o�^�E�X�V�pPL/SQL�\�^
  TYPE delivery_charges_id_ttype     IS TABLE OF xxwip_delivery_charges.delivery_charges_id%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �^���}�X�^ID
  TYPE p_b_classe_ttype              IS TABLE OF xxwip_delivery_charges.p_b_classe%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �x�������敪
  TYPE goods_classe_ttype            IS TABLE OF xxwip_delivery_charges.goods_classe%TYPE
                                        INDEX BY BINARY_INTEGER;  -- ���i�敪
  TYPE delivery_company_code_ttype   IS TABLE OF xxwip_delivery_charges.delivery_company_code%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �^���Ǝ�
  TYPE shipping_address_classe_ttype IS TABLE OF xxwip_delivery_charges.shipping_address_classe%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �z���敪
  TYPE delivery_distance_ttype       IS TABLE OF xxwip_delivery_charges.delivery_distance%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �^������
  TYPE delivery_weight_ttype         IS TABLE OF xxwip_delivery_charges.delivery_weight%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �d��
  TYPE start_date_active_ttype       IS TABLE OF xxwip_delivery_charges.start_date_active%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �K�p�J�n��
  TYPE end_date_active_ttype         IS TABLE OF xxwip_delivery_charges.end_date_active%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �K�p�I����
  TYPE shipping_expenses_ttype       IS TABLE OF xxwip_delivery_charges.shipping_expenses%TYPE
                                        INDEX BY BINARY_INTEGER;  -- �^����
  TYPE leaf_consolid_add_ttype       IS TABLE OF xxwip_delivery_charges.leaf_consolid_add%TYPE
                                        INDEX BY BINARY_INTEGER;  -- ���[�t���ڊ���
--
  -- ���b�Z�[�WPL/SQL�\�^
  TYPE msg_ttype                      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v��ID�pPL/SQL�\
  request_id_tab                    request_id_ttype;               -- �v��ID
--
  -- �o�^�pPL/SQL�\
  delivery_charges_id_ins_tab       delivery_charges_id_ttype;      -- �^���}�X�^ID
  p_b_classe_ins_tab                p_b_classe_ttype;               -- �x�������敪
  goods_classe_ins_tab              goods_classe_ttype;             -- ���i�敪
  delivery_company_code_ins_tab     delivery_company_code_ttype;    -- �^���Ǝ�
  ship_address_classe_ins_tab       shipping_address_classe_ttype;  -- �z���敪
  delivery_distance_ins_tab         delivery_distance_ttype;        -- �^������
  delivery_weight_ins_tab           delivery_weight_ttype;          -- �d��
  start_date_active_ins_tab         start_date_active_ttype;        -- �K�p�J�n��
  end_date_active_ins_tab           end_date_active_ttype;          -- �K�p�I����
  shipping_expenses_ins_tab         shipping_expenses_ttype;        -- �^����
  leaf_consolid_add_ins_tab         leaf_consolid_add_ttype;        -- ���[�t���ڊ���
--
  -- �X�V�pPL/SQL�\
  delivery_charges_id_upd_tab       delivery_charges_id_ttype;      -- �^���}�X�^ID
  p_b_classe_upd_tab                p_b_classe_ttype;               -- �x�������敪
  goods_classe_upd_tab              goods_classe_ttype;             -- ���i�敪
  delivery_company_code_upd_tab     delivery_company_code_ttype;    -- �^���Ǝ�
  ship_address_classe_upd_tab       shipping_address_classe_ttype;  -- �z���敪
  delivery_distance_upd_tab         delivery_distance_ttype;        -- �^������
  delivery_weight_upd_tab           delivery_weight_ttype;          -- �d��
  start_date_active_upd_tab         start_date_active_ttype;        -- �K�p�J�n��
  end_date_active_upd_tab           end_date_active_ttype;          -- �K�p�I����
  shipping_expenses_upd_tab         shipping_expenses_ttype;        -- �^����
  leaf_consolid_add_upd_tab         leaf_consolid_add_ttype;        -- ���[�t���ڊ���
--
  -- �f�[�^�_���v�pPL/SQL�\
  warn_dump_tab                     msg_ttype;                      -- �x���f�[�^�_���v
  normal_dump_tab                   msg_ttype;                      -- ����f�[�^�_���v
--
  -- �J�E���^
  gn_request_id_cnt   NUMBER := 0;   -- �v��ID�J�E���g
  gn_ins_tab_cnt      NUMBER := 0;   -- �o�^�pPL/SQL�\�J�E���g
  gn_upd_tab_cnt      NUMBER := 0;   -- �X�V�pPL/SQL�\�J�E���g
  gn_err_msg_cnt      NUMBER := 0;   -- �x���G���[���b�Z�[�W�\�J�E���g
--
-- v1.3 ADD START
  gv_prod_div         VARCHAR2(1);   -- ���i�敪
-- v1.3 ADD END
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : �\���b�N�擾����(E-2)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    cv_xxwip_delivery_charges     CONSTANT VARCHAR2(40) := '�^���A�h�I���}�X�^';
    cv_xxwip_delivery_charges_if  CONSTANT VARCHAR2(40) := '�^���A�h�I���}�X�^�C���^�t�F�[�X';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �^���A�h�I���}�X�^�C���^�t�F�[�X���b�N�J�[�\��
    CURSOR xxwip_delivery_charges_if_cur(lt_request_id xxwip_delivery_charges_if.request_id%TYPE)
    IS
      SELECT /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */            -- 2008/11/11 �����w�E#589 Add
             xdci.delivery_charges_if_id        -- �^���A�h�I���}�X�^�C���^�t�F�[�XID
      FROM   xxwip_delivery_charges_if    xdci  -- �^���A�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xdci.request_id = lt_request_id    -- �v��ID
      FOR UPDATE NOWAIT
    ;
--
    -- �^���A�h�I���}�X�^���b�N�J�[�\��
    CURSOR xxwip_delivery_charges_cur
    IS
      SELECT xdc.delivery_charges_id            -- �^���A�h�I���}�X�^ID
      FROM   xxwip_delivery_charges    xdc      -- �^���A�h�I���}�X�^
      FOR UPDATE NOWAIT
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
    -- ==============================
    -- ���b�N�擾
    -- ==============================
    -- �^���A�h�I���}�X�^�C���^�t�F�[�X�̃��b�N���擾
    BEGIN
      <<request_id_loop>>
      FOR req_id_cnt IN 1..request_id_tab.COUNT LOOP
        <<xdci_lock_loop>>
        FOR xdc_cnt IN xxwip_delivery_charges_if_cur(request_id_tab(req_id_cnt)) LOOP
          EXIT;
        END LOOP xdci_lock_loop;
      END LOOP request_id_loop;
--    
    EXCEPTION
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip          -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10004 -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
                     ,gv_tkn_table      -- �g�[�N��TABLE
                     ,cv_xxwip_delivery_charges_if  -- �e�[�u�����F�^���A�h�I���}�X�^�C���^�t�F�[�X
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- �^���A�h�I���}�X�^�̃��b�N���擾
    BEGIN
      <<xdc_lock_loop>>
      FOR loop_cnt IN xxwip_delivery_charges_cur LOOP
        EXIT;
      END LOOP xdc_lock_loop;
--
    EXCEPTION
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip          -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10004 -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
                     ,gv_tkn_table      -- �g�[�N��TABLE
                     ,cv_xxwip_delivery_charges     -- �e�[�u�����F�^���A�h�I���}�X�^
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xxwip_delivery_charges_if_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_if_cur;
      END IF;
      IF (xxwip_delivery_charges_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xxwip_delivery_charges_if_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_if_cur;
      END IF;
      IF (xxwip_delivery_charges_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xxwip_delivery_charges_if_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_if_cur;
      END IF;
      IF (xxwip_delivery_charges_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : �f�[�^�_���v�擾����
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,  
                                                  -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
    ov_dump                       OUT VARCHAR2,   -- �f�[�^�_���v������
    ov_errbuf                     OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                    OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                     OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ov_dump :=  ir_xxwip_delivery_charges_if.p_b_classe                 -- �x�������敪
                || gv_msg_comma ||  
                ir_xxwip_delivery_charges_if.goods_classe               -- ���i�敪
                || gv_msg_comma ||
                ir_xxwip_delivery_charges_if.delivery_company_code      -- �^���Ǝ�
                || gv_msg_comma ||
                ir_xxwip_delivery_charges_if.shipping_address_classe    -- �z���敪
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.delivery_distance) -- �^������
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.delivery_weight)   -- �d��
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.start_date_active, 'YYYY/MM/DD')  -- �K�p�J�n��
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.shipping_expenses) -- �^����
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.leaf_consolid_add) -- ���[�t���ڊ���
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
   * Procedure Name   : del_duplication_data
   * Description      : �d���f�[�^���O�����iE-3�j
   ***********************************************************************************/
  PROCEDURE del_duplication_data(
    it_request_id IN  xxwip_delivery_distance_if.request_id%TYPE,     -- 1.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_duplication_data'; -- �v���O������
    cv_item       CONSTANT VARCHAR2(100) := '�f�[�^';
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
    lr_xdci_if_data xxwip_delivery_charges_if%ROWTYPE;  -- �d�����R�[�h
    lv_dump         VARCHAR2(5000);                     -- �f�[�^�_���v
    lv_warn_msg     VARCHAR2(5000);                     -- �x�����b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �d���f�[�^�擾�J�[�\��
    CURSOR xdci_duplication_chk_cur IS
      SELECT /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */                  -- 2008/11/11 �����w�E#589 Add
          COUNT(xdci.delivery_charges_if_id) cnt  -- �f�[�^�J�E���g
        , xdci.p_b_classe                         -- �x�������敪
        , xdci.goods_classe                       -- ���i�敪
        , xdci.delivery_company_code              -- �^���Ǝ�
        , xdci.shipping_address_classe            -- �z���敪
        , xdci.delivery_distance                  -- �^������
        , xdci.delivery_weight                    -- �d��
        , xdci.start_date_active                  -- �K�p�J�n��
      FROM  xxwip_delivery_charges_if xdci        -- �^���A�h�I���}�X�^�C���^�t�F�[�X
      WHERE xdci.request_id   = it_request_id     -- �v��ID
-- v1.3 ADD START
        AND xdci.goods_classe = gv_prod_div       -- ���i�敪
-- v1.3 ADD END
      GROUP BY 
          xdci.p_b_classe                         -- �x�������敪
        , xdci.goods_classe                       -- ���i�敪
        , xdci.delivery_company_code              -- �^���Ǝ�
        , xdci.shipping_address_classe            -- �z���敪
        , xdci.delivery_distance                  -- �^������
        , xdci.delivery_weight                    -- �d��
        , xdci.start_date_active                  -- �K�p�J�n��
      ;
--
    -- �G���[�f�[�^�J�[�\��
    CURSOR xdci_err_data_cur(
        lt_p_b_classe         xxwip_delivery_charges_if.p_b_classe%TYPE             -- �x�������敪
      , lt_goods_classe       xxwip_delivery_charges_if.goods_classe%TYPE           -- ���i�敪
      , lt_deli_company_code  xxwip_delivery_charges_if.delivery_company_code%TYPE  -- �^���Ǝ�
      , lt_ship_address_cls   xxwip_delivery_charges_if.shipping_address_classe%TYPE  -- �z���敪
      , lt_delivery_distance  xxwip_delivery_charges_if.delivery_distance%TYPE      -- �^������
      , lt_delivery_weight    xxwip_delivery_charges_if.delivery_weight%TYPE        -- �d��
      , lt_start_date_active  xxwip_delivery_charges_if.start_date_active%TYPE      -- �K�p�J�n��
      ) 
    IS
      SELECT  /*+ INDEX( xdci xxwip_deli_char_if_n02 ) */                 -- 2008/11/11 �����w�E#589 Add
              xdci.delivery_charges_if_id   delivery_charges_if_id        -- �^���}�X�^ID
          ,   xdci.p_b_classe               p_b_classe                    -- �x�������敪
          ,   xdci.goods_classe             goods_classe                  -- ���i�敪
          ,   xdci.delivery_company_code    delivery_company_code         -- �^���Ǝ�
          ,   xdci.shipping_address_classe  shipping_address_classe       -- �z���敪
          ,   xdci.delivery_distance        delivery_distance             -- �^������
          ,   xdci.delivery_weight          delivery_weight               -- �d��
          ,   xdci.start_date_active        start_date_active             -- �K�p�J�n��
          ,   xdci.shipping_expenses        shipping_expenses             -- �^����
          ,   xdci.leaf_consolid_add        leaf_consolid_add             -- ���[�t���ڊ���
      FROM    xxwip_delivery_charges_if     xdci                -- �^���A�h�I���}�X�^�C���^�t�F�[�X
      WHERE   xdci.p_b_classe               = lt_p_b_classe               -- �x�������敪
        AND   xdci.goods_classe             = lt_goods_classe             -- ���i�敪
        AND   xdci.delivery_company_code    = lt_deli_company_code        -- �^���Ǝ�
        AND   xdci.shipping_address_classe  = lt_ship_address_cls         -- �z���敪
        AND   xdci.delivery_distance        = lt_delivery_distance        -- �^������
        AND   xdci.delivery_weight          = lt_delivery_weight          -- �d��
        AND   xdci.start_date_active        = lt_start_date_active        -- �K�p�J�n��
      ORDER BY delivery_charges_if_id
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
    -- �d���`�F�b�N�J�[�\��
    -- ===============================
    << xdci_dupl_chk_loop >>
    FOR xdci_dupl_chk IN xdci_duplication_chk_cur LOOP
      -- �J�E���g2���ȏ�̓f�[�^���d�����Ă���
      IF (xdci_dupl_chk.cnt > 1) THEN
        -- ===============================
        -- �G���[�f�[�^�J�[�\��
        -- ===============================
        <<xdci_err_data_loop>>
        FOR xdci_err_data IN xdci_err_data_cur(
              xdci_dupl_chk.p_b_classe              -- �x�������敪
            , xdci_dupl_chk.goods_classe            -- ���i�敪
            , xdci_dupl_chk.delivery_company_code   -- �^���Ǝ�
            , xdci_dupl_chk.shipping_address_classe -- �z���敪
            , xdci_dupl_chk.delivery_distance       -- �^������
            , xdci_dupl_chk.delivery_weight         -- �d��
            , xdci_dupl_chk.start_date_active       -- �K�p�J�n��
        ) LOOP
--
          -- �d���f�[�^�����R�[�h�ɃZ�b�g
          lr_xdci_if_data.p_b_classe              := xdci_err_data.p_b_classe;
                                                      -- �x�������敪
          lr_xdci_if_data.goods_classe            := xdci_err_data.goods_classe;
                                                      -- ���i�敪
          lr_xdci_if_data.delivery_company_code   := xdci_err_data.delivery_company_code;
                                                      -- �^���Ǝ�
          lr_xdci_if_data.shipping_address_classe := xdci_err_data.shipping_address_classe;
                                                      -- �z���敪
          lr_xdci_if_data.delivery_distance       := xdci_err_data.delivery_distance;
                                                      -- �^������
          lr_xdci_if_data.delivery_weight         := xdci_err_data.delivery_weight;         
                                                      -- �d��
          lr_xdci_if_data.start_date_active       := xdci_err_data.start_date_active;
                                                      -- �K�p�J�n��
          lr_xdci_if_data.shipping_expenses       := xdci_err_data.shipping_expenses;
                                                      -- �^����
          lr_xdci_if_data.leaf_consolid_add       := xdci_err_data.leaf_consolid_add;
                                                      -- ���[�t���ڊ���
--
          -- ===============================
          -- �f�[�^�_���v�擾����
          -- ===============================
          get_data_dump(
              ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.�d���f�[�^���R�[�h
            , ov_dump    => lv_dump       -- �f�[�^�_���v������
            , ov_errbuf  => lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode => lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg  => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--          
          -- �f�[�^�_���v�擾�������G���[�̏ꍇ
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ===============================
          -- �x���G���[���b�Z�[�W�擾
          -- ===============================
          -- �G���[���b�Z�[�W�擾
          lv_warn_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwip     -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                        , gv_msg_xxwip10023 
                                       -- ���b�Z�[�W�FAPP-XXWIP-10023 �f�[�^�d���G���[���b�Z�[�W
                        , gv_tkn_item  -- �g�[�N��item
                        , cv_item      -- item��
                        ),1,5000);
--
          -- ===============================
          -- �x���f�[�^�_���vPL/SQL�\����
          -- ===============================
          -- �f�[�^�_���v���x���f�[�^�_���vPL/SQL�\�ɃZ�b�g
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_dump;
--
          -- �x�����b�Z�[�W���x���f�[�^�_���vPL/SQL�\�ɃZ�b�g
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_warn_msg;
--
          -- �X�L�b�v�����J�E���g
          gn_warn_cnt   := gn_warn_cnt + 1;
--
        END LOOP xdci_err_data_loop;
--
        -- ===============================
        -- �G���[�f�[�^�폜
        -- ===============================
        DELETE /*+ INDEX( xdci xxwip_deli_char_if_n02 ) */                            -- 2008/11/11 �����w�E#589 Add
        FROM xxwip_delivery_charges_if xdci  -- �^���A�h�I���C���^�t�F�[�X
        WHERE   xdci.p_b_classe               = xdci_dupl_chk.p_b_classe              -- �x�������敪
          AND   xdci.goods_classe             = xdci_dupl_chk.goods_classe            -- ���i�敪
          AND   xdci.delivery_company_code    = xdci_dupl_chk.delivery_company_code   -- �^���Ǝ�
          AND   xdci.shipping_address_classe  = xdci_dupl_chk.shipping_address_classe -- �z���敪
          AND   xdci.delivery_distance        = xdci_dupl_chk.delivery_distance       -- �^������
          AND   xdci.delivery_weight          = xdci_dupl_chk.delivery_weight         -- �d��
          AND   xdci.start_date_active        = xdci_dupl_chk.start_date_active       -- �K�p�J�n��
        ;
--
       -- ===============================
       --  OUT�p�����[�^�Z�b�g
       -- ===============================
       ov_retcode := gv_status_warn;
--
      END IF;
--
    END LOOP xdci_dupl_chk_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (xdci_duplication_chk_cur%ISOPEN) THEN
        CLOSE xdci_duplication_chk_cur;
      END IF;
      IF (xdci_err_data_cur%ISOPEN) THEN
        CLOSE xdci_err_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xdci_duplication_chk_cur%ISOPEN) THEN
        CLOSE xdci_duplication_chk_cur;
      END IF;
      IF (xdci_err_data_cur%ISOPEN) THEN
        CLOSE xdci_err_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xdci_duplication_chk_cur%ISOPEN) THEN
        CLOSE xdci_duplication_chk_cur;
      END IF;
      IF (xdci_err_data_cur%ISOPEN) THEN
        CLOSE xdci_err_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_duplication_data;
--
  /**********************************************************************************
   * Procedure Name   : master_data_chk
   * Description      : �}�X�^�f�[�^�`�F�b�N����(E-5)
   ***********************************************************************************/
  PROCEDURE master_data_chk(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,
                                  -- 1.�^���A�h�I���}�X�^I/F���R�[�h
    iv_dump       IN  VARCHAR2,   -- �f�[�^�_���v
    ov_errbuf     OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'master_data_chk'; -- �v���O������
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
    -- �G���[�L�[����
    cv_category_set             CONSTANT VARCHAR2(50) :=  '�J�e�S���Z�b�g��';
                                -- �G���[�L�[���ځF�J�e�S���Z�b�g��
    cv_category_set_name        CONSTANT VARCHAR2(50) :=  '���i�敪';
                                -- �G���[�L�[���ځF���i�敪
    cv_lookup_type              CONSTANT VARCHAR2(50) :=  '�N�C�b�N�R�[�h�^�C�v';
                                -- �G���[�L�[���ځF�N�C�b�N�R�[�h�^�C�v
    cv_lookup_code              CONSTANT VARCHAR2(50) :=  '�N�C�b�N�R�[�h';
                                -- �G���[�L�[���ځF�N�C�b�N�R�[�h
    cv_delivery_company_code    CONSTANT VARCHAR2(50) :=  '�^���Ǝ҃R�[�h';
                                -- �G���[�L�[���ځF�^���Ǝ҃R�[�h
--
    -- �N�C�b�N�R�[�h
    cv_p_b_classe_type          CONSTANT VARCHAR2(50) :=  'XXWIP_PAYCHARGE_TYPE';
                                -- �N�C�b�N�R�[�h�^�C�v�F�x�������敪
    cv_p_b_classe_type_name     CONSTANT VARCHAR2(50) :=  'XXWIP.�x�������敪';
                                -- �N�C�b�N�R�[�h�^�C�v�F�x�������敪
    cv_ship_address_cls_type    CONSTANT VARCHAR2(50) :=  'XXCMN_SHIP_METHOD';
                                -- �N�C�b�N�R�[�h�^�C�v�F�z���敪
    cv_ship_addr_cls_type_name  CONSTANT VARCHAR2(50) :=  'XXWIP.�z���敪';
                                -- �N�C�b�N�R�[�h�^�C�v�F�z���敪
--
    -- �G���[�e�[�u��
    cv_xxcmn_categories_v       CONSTANT VARCHAR2(50) :=  '�i�ڃJ�e�S�����VIEW';
    cv_xxcmn_lookup_values_v    CONSTANT VARCHAR2(50) :=  '�N�C�b�N�R�[�h���VIEW';
    cv_xxwip_delivery_company   CONSTANT VARCHAR2(50) :=  '�^���p�^���Ǝ҃A�h�I���}�X�^';
--
    -- *** ���[�J���ϐ� ***
    lv_err_tbl                  VARCHAR2(50);   -- �G���[�e�[�u����
    lv_err_key                  VARCHAR2(2000); -- �G���[�L�[����
    ln_exist_chk                NUMBER;         -- ���݃`�F�b�N�J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    
    -- *** �T�u�v���O���� ***
    -- ===============================
    -- �x���G���[���b�Z�[�W�\����
    -- ===============================
    PROCEDURE set_err_msg
    IS
    BEGIN
      -- �x���f�[�^�_���vPL/SQL�\����
      -- 1���ڂ̌x���̏ꍇ�̂݁A�_���v�𓊓�
      IF (lv_retcode = gv_status_normal) THEN
        gn_err_msg_cnt := gn_err_msg_cnt + 1;
        warn_dump_tab(gn_err_msg_cnt) := iv_dump;
      END IF;
--
      -- �x�����b�Z�[�W�𓊓�
      gn_err_msg_cnt := gn_err_msg_cnt + 1;
      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
      -- �x���ɃZ�b�g
      lv_retcode := gv_status_warn;
--
    END set_err_msg;
--
    -- ===============================
    -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
    -- ===============================
    PROCEDURE get_no_data_msg
    IS
    BEGIN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- ���W���[�������́FXXCMN ����
                   ,gv_msg_xxcmn10001      -- ���b�Z�[�W�FAPP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                   ,gv_tkn_table           -- �g�[�N���FTABLE
                   ,lv_err_tbl             -- �G���[�e�[�u����
                   ,gv_tkn_key             -- �g�[�N���FKEY
                   ,lv_err_key             -- �G���[�L�[����
                  ),1,5000);
--
      -- �x���G���[���b�Z�[�W�\����
      set_err_msg;
    END;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    lv_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �x�������敪�`�F�b�N
    -- ===============================
    SELECT  COUNT(xlvv.lookup_code)  -- ���b�N�A�b�v�R�[�h
    INTO    ln_exist_chk
    FROM    xxcmn_lookup_values_v xlvv                -- �N�C�b�N�R�[�h���VIEW
    WHERE   xlvv.lookup_type  = cv_p_b_classe_type    -- �N�C�b�N�R�[�h�^�C�v�F�x�������敪
      AND   xlvv.lookup_code  = ir_xxwip_delivery_charges_if.p_b_classe   -- �x�������敪
      AND   xlvv.start_date_active  <= TRUNC(SYSDATE)   -- �K�p�J�n��
      AND  (xlvv.end_date_active    IS NULL
            OR xlvv.end_date_active >= TRUNC(SYSDATE))  -- �K�p�I����
      AND   ROWNUM = 1
    ;
--
    IF (ln_exist_chk = 0) THEN
      -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
      lv_err_tbl := cv_xxcmn_lookup_values_v;   -- �G���[�e�[�u�����F�N�C�b�N�R�[�h���VIEW
      lv_err_key := cv_lookup_type          ||  -- �G���[�L�[���ځF�N�C�b�N�R�[�h�^�C�v
                    gv_msg_part             ||  -- ��؂蕶��
                    cv_p_b_classe_type_name ||  -- �N�C�b�N�R�[�h�F�x�������敪
                    gv_msg_comma            ||  -- ��؂蕶��
                    cv_lookup_code          ||  -- �G���[�L�[���ځF�N�C�b�N�R�[�h
                    gv_msg_part             ||  -- ��؂蕶��
                    ir_xxwip_delivery_charges_if.p_b_classe;
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      get_no_data_msg;
    END IF;
--
    -- ===============================
    -- ���i�敪�`�F�b�N
    -- ===============================
    -- �i�ڃJ�e�S�����VIEW���`�F�b�N
    SELECT  COUNT(xcv.category_set_id)
    INTO    ln_exist_chk
    FROM    xxcmn_categories_v xcv  -- �i�ڃJ�e�S�����VIEW
    WHERE   xcv.category_set_name = cv_category_set_name                        -- �J�e�S���Z�b�g��
    AND     xcv.segment1          = ir_xxwip_delivery_charges_if.goods_classe   -- ���i�敪
    AND     ROWNUM = 1
      ;
    IF (ln_exist_chk = 0) THEN
         -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxcmn_categories_v;    -- �G���[�e�[�u�����F�i�ڃJ�e�S�����VIEW
        lv_err_key := cv_category_set_name  ||  -- �G���[�L�[���ځF���i�敪
                      gv_msg_part           ||  -- ��؂蕶��
                      ir_xxwip_delivery_charges_if.goods_classe;
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
    ELSE
      -- ���i�敪�`�F�b�N������̏ꍇ
      -- ===============================
      -- �^���Ǝ҃`�F�b�N
      -- ===============================
      SELECT  COUNT(xdc.delivery_company_id)  -- �^���Ǝ�
      INTO    ln_exist_chk
      FROM    xxwip_delivery_company xdc  -- �^���p�^���Ǝ҃}�X�^
      WHERE   xdc.goods_classe          = ir_xxwip_delivery_charges_if.goods_classe
                                                                    -- ���i�敪
        AND   xdc.delivery_company_code = ir_xxwip_delivery_charges_if.delivery_company_code
                                                                    -- �^���Ǝ�
        AND   xdc.start_date_active    <= TRUNC(SYSDATE)            -- �K�p�J�n��
        AND   xdc.end_date_active      >= TRUNC(SYSDATE)            -- �K�p�I����
        AND   ROWNUM = 1
      ;
      IF (ln_exist_chk = 0) THEN
        -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
        lv_err_tbl := cv_xxwip_delivery_company; -- �G���[�e�[�u�����F�^���p�^���Ǝ҃A�h�I���}�X�^
        lv_err_key := cv_delivery_company_code     || -- �G���[�L�[���ځF�^���Ǝ҃R�[�h
                      gv_msg_part                  || -- ��؂蕶��
                      ir_xxwip_delivery_charges_if.delivery_company_code;
--
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
        get_no_data_msg;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �z���敪�`�F�b�N
    -- ===============================
    SELECT  COUNT(xlvv.lookup_code)
    INTO    ln_exist_chk
    FROM    xxcmn_lookup_values_v xlvv                    -- �N�C�b�N�R�[�h���VIEW
    WHERE   xlvv.lookup_type  = cv_ship_address_cls_type  -- �N�C�b�N�R�[�h�^�C�v�F�z���敪
      AND   xlvv.lookup_code  = ir_xxwip_delivery_charges_if.shipping_address_classe -- �z���敪
      AND   xlvv.start_date_active  <= TRUNC(SYSDATE)   -- �K�p�J�n��
      AND  (xlvv.end_date_active    IS NULL
            OR xlvv.end_date_active >= TRUNC(SYSDATE))  -- �K�p�I����
      AND   ROWNUM = 1
    ;
    IF (ln_exist_chk = 0) THEN
       -- �G���[�e�[�u�����A�G���[�L�[���ڃZ�b�g
      lv_err_tbl := cv_xxcmn_lookup_values_v; -- �G���[�e�[�u�����F�N�C�b�N�R�[�h���VIEW
      lv_err_key := cv_lookup_type              ||  -- �G���[�L�[���ځF�N�C�b�N�R�[�h�^�C�v
                    gv_msg_part                 ||  -- ��؂蕶��
                    cv_ship_addr_cls_type_name  ||  -- �N�C�b�N�R�[�h�F�z���敪
                    gv_msg_comma                ||  -- ��؂蕶��
                    cv_lookup_code              ||  -- �G���[�L�[���ځF�N�C�b�N�R�[�h
                    gv_msg_part                 ||
                    ir_xxwip_delivery_charges_if.shipping_address_classe;
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      get_no_data_msg;
    END IF;
--
    -- ===============================
    -- OUT�p�����[�^�Z�b�g
    -- ===============================
    ov_retcode := lv_retcode;
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
  END master_data_chk;
--
  /**********************************************************************************
   * Procedure Name   : set_ins_tab
   * Description      : �o�^�pPL/SQL�\����(E-6)
   ***********************************************************************************/
  PROCEDURE set_ins_tab(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,  
                                                    -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
    ov_errbuf                     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ins_tab'; -- �v���O������
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
    -- �o�^�pPL/SQL�\�ɃZ�b�g
    -- ===============================
    -- �o�^�p�����J�E���g
    gn_ins_tab_cnt := gn_ins_tab_cnt + 1;
--
    -- �l�Z�b�g
    SELECT xxwip_delivery_charges_id_s1.NEXTVAL       -- �^���}�X�^ID
    INTO   delivery_charges_id_ins_tab(gn_ins_tab_cnt)
    FROM   dual;
    p_b_classe_ins_tab(gn_ins_tab_cnt)              
        :=  ir_xxwip_delivery_charges_if.p_b_classe;              -- �x�������敪
    goods_classe_ins_tab(gn_ins_tab_cnt)            
        :=  ir_xxwip_delivery_charges_if.goods_classe;            -- ���i�敪
    delivery_company_code_ins_tab(gn_ins_tab_cnt)   
        :=  ir_xxwip_delivery_charges_if.delivery_company_code;   -- �^���Ǝ�
    ship_address_classe_ins_tab(gn_ins_tab_cnt)    
        :=  ir_xxwip_delivery_charges_if.shipping_address_classe; -- �z���敪
    delivery_distance_ins_tab(gn_ins_tab_cnt)       
        :=  ir_xxwip_delivery_charges_if.delivery_distance;       -- �^������
    delivery_weight_ins_tab(gn_ins_tab_cnt)         
        :=  ir_xxwip_delivery_charges_if.delivery_weight;         -- �d��
    start_date_active_ins_tab(gn_ins_tab_cnt)       
        :=  ir_xxwip_delivery_charges_if.start_date_active;       -- �K�p�J�n��
    shipping_expenses_ins_tab(gn_ins_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.shipping_expenses;       -- �^����
    leaf_consolid_add_ins_tab(gn_ins_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.leaf_consolid_add;       -- ���[�t���ڊ���
--
  EXCEPTION
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
  END set_ins_tab;
--
  /**********************************************************************************
   * Procedure Name   : set_upd_tab
   * Description      : �X�V�pPL/SQL�\����(E-8)
   ***********************************************************************************/
  PROCEDURE set_upd_tab(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,
                                                  -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
    ov_errbuf                     OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                    OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                     OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upd_tab'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �X�V�pPL/SQL�\�ɃZ�b�g
    -- ===============================
    -- �X�V�p�����J�E���g
    gn_upd_tab_cnt := gn_upd_tab_cnt + 1;
--
    -- �l�Z�b�g
    p_b_classe_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.p_b_classe;              -- �x�������敪
    goods_classe_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.goods_classe;            -- ���i�敪
    delivery_company_code_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.delivery_company_code;   -- �^���Ǝ�
    ship_address_classe_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.shipping_address_classe; -- �z���敪
    delivery_distance_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.delivery_distance;       -- �^������
    delivery_weight_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.delivery_weight;         -- �d��
    start_date_active_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.start_date_active;       -- �K�p�J�n��
    shipping_expenses_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.shipping_expenses;       -- �^����
    leaf_consolid_add_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.leaf_consolid_add;       -- ���[�t���ڊ���
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
  END set_upd_tab;

  /**********************************************************************************
   * Procedure Name   : get_ins_data
   * Description      : �V�K�o�^�f�[�^�擾����(E-4)
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    it_request_id IN  xxwip_delivery_charges_if.request_id%TYPE,  -- 1.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lr_xdci_if_data xxwip_delivery_charges_if%ROWTYPE;  -- �^���A�h�I���}�X�^I/F���R�[�h�^
    lv_dump         VARCHAR2(5000);                     -- �f�[�^�_���v
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �o�^�f�[�^�擾�J�[�\��
    CURSOR get_ins_data_cur IS
      SELECT  /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */                 -- 2008/11/11 �����w�E#589 Add
              xdci.p_b_classe               -- �x�������敪
            , xdci.goods_classe             -- ���i�敪
            , xdci.delivery_company_code    -- �^���Ǝ�
            , xdci.shipping_address_classe  -- �z���敪
            , xdci.delivery_distance        -- �^������
            , xdci.delivery_weight          -- �d��
            , xdci.start_date_active        -- �K�p�J�n��
            , xdci.shipping_expenses        -- �^����
            , xdci.leaf_consolid_add        -- ���[�t���ڊ���
      FROM  xxwip_delivery_charges_if xdci  -- �^���A�h�I���C���^�t�F�[�X
      WHERE xdci.request_id   = it_request_id  -- �v��ID
-- v1.3 ADD START
        AND xdci.goods_classe = gv_prod_div    -- ���i�敪
-- v1.3 ADD END
        AND NOT EXISTS(
                  SELECT  'X'
                  FROM    xxwip_delivery_charges xdc                           -- �^���A�h�I���}�X�^
                  WHERE   xdc.p_b_classe              = xdci.p_b_classe               -- �x�������敪
                    AND   xdc.goods_classe            = xdci.goods_classe             -- ���i�敪
                    AND   xdc.delivery_company_code   = xdci.delivery_company_code    -- �^���Ǝ�
                    AND   xdc.shipping_address_classe = xdci.shipping_address_classe  -- �z���敪
                    AND   xdc.delivery_distance       = xdci.delivery_distance        -- �^������
                    AND   xdc.delivery_weight         = xdci.delivery_weight          -- �d��
                    AND   xdc.start_date_active       = xdci.start_date_active        -- �K�p�J�n��
            );        
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
    -- =============================
    -- �o�^�f�[�^�擾
    -- =============================
    <<xdci_ins_data_loop>>
    FOR xdci_ins_dat IN get_ins_data_cur LOOP
      -- �^���A�h�I���}�X�^I/F���R�[�h�^�Ƀf�[�^���Z�b�g����
      lr_xdci_if_data.p_b_classe
          := xdci_ins_dat.p_b_classe;               -- �x�������敪
      lr_xdci_if_data.goods_classe
          := xdci_ins_dat.goods_classe;             -- ���i�敪
      lr_xdci_if_data.delivery_company_code
          := xdci_ins_dat.delivery_company_code;    -- �^���Ǝ�
      lr_xdci_if_data.shipping_address_classe
          := xdci_ins_dat.shipping_address_classe;  -- �z���敪
      lr_xdci_if_data.delivery_distance
          := xdci_ins_dat.delivery_distance;        -- �^������
      lr_xdci_if_data.delivery_weight
          := xdci_ins_dat.delivery_weight;          -- �d��
      lr_xdci_if_data.start_date_active
          := xdci_ins_dat.start_date_active;        -- �K�p�J�n��
      lr_xdci_if_data.shipping_expenses
          := xdci_ins_dat.shipping_expenses;        -- �^����
      lr_xdci_if_data.leaf_consolid_add
          := xdci_ins_dat.leaf_consolid_add;        -- ���[�t���ڊ���
--
      -- ===============================
      -- �f�[�^�_���v�擾����
      -- ===============================
      get_data_dump(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
        , ov_dump    => lv_dump       -- �f�[�^�_���v������
        , ov_errbuf  => lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode => lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg  => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- E-5.�}�X�^�f�[�^�`�F�b�N����
      -- =============================
      master_data_chk(
          ir_xxwip_delivery_charges_if  =>  lr_xdci_if_data -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
        , iv_dump                       =>  lv_dump         -- 2.�f�[�^�_���v
        , ov_errbuf                     =>  lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode                    =>  lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg                     =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- OUT�p�����[�^���x���ɃZ�b�g
        ov_retcode := gv_status_warn;
--
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- ����̏ꍇ
      ELSE
        -- =============================
        -- E-7.�o�^�pPL/SQL�\����
        -- =============================
        set_ins_tab(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
         ,ov_errbuf  => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg  => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        -- ����̏ꍇ
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- ����f�[�^����
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- ����f�[�^�_���vPL/SQL�\����
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
--      
      END IF;
--
    END LOOP xdci_ins_data_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (get_ins_data_cur%ISOPEN) THEN
        CLOSE get_ins_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_ins_data_cur%ISOPEN) THEN
        CLOSE get_ins_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_ins_data_cur%ISOPEN) THEN
        CLOSE get_ins_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ins_data;
--
  /**********************************************************************************
   * Procedure Name   : get_upd_data
   * Description      : �X�V�f�[�^�擾����(E-7)
   ***********************************************************************************/
  PROCEDURE get_upd_data(
    it_request_id IN  xxwip_delivery_charges_if.request_id%TYPE,  -- 1.�v��ID,
    ov_errbuf     OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           # �Œ� #
    ov_retcode    OUT VARCHAR2,   --   ���^�[���E�R�[�h             # �Œ� #
    ov_errmsg     OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upd_data'; -- �v���O������
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
    lr_xdci_if_data xxwip_delivery_charges_if%ROWTYPE;  -- �^���A�h�I���}�X�^I/F���R�[�h�^
    lv_dump         VARCHAR2(5000);                     -- �f�[�^�_���v
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �X�V�f�[�^�擾�J�[�\��
    CURSOR get_upd_data_cur IS
      SELECT  /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */                   -- 2008/11/11 �����w�E#589 Add
              xdci.p_b_classe               -- �x�������敪
            , xdci.goods_classe             -- ���i�敪
            , xdci.delivery_company_code    -- �^���Ǝ�
            , xdci.shipping_address_classe  -- �z���敪
            , xdci.delivery_distance        -- �^������
            , xdci.delivery_weight          -- �d��
            , xdci.start_date_active        -- �K�p�J�n��
            , xdci.shipping_expenses        -- �^����
            , xdci.leaf_consolid_add        -- ���[�t���ڊ���
      FROM  xxwip_delivery_charges_if xdci  -- �^���A�h�I���C���^�t�F�[�X
      WHERE xdci.request_id   = it_request_id   -- �v��ID
-- v1.3 ADD START
        AND xdci.goods_classe = gv_prod_div     -- ���i�敪
-- v1.3 ADD END
        AND EXISTS(
                  SELECT  'X'
                  FROM  xxwip_delivery_charges xdc  -- �^���A�h�I���}�X�^
                  WHERE xdc.p_b_classe              = xdci.p_b_classe               -- �x�������敪
                    AND xdc.goods_classe            = xdci.goods_classe             -- ���i�敪
                    AND xdc.delivery_company_code   = xdci.delivery_company_code    -- �^���Ǝ�
                    AND xdc.shipping_address_classe = xdci.shipping_address_classe  -- �z���敪
                    AND xdc.delivery_distance       = xdci.delivery_distance        -- �^������
                    AND xdc.delivery_weight         = xdci.delivery_weight          -- �d��
                    AND xdc.start_date_active       = xdci.start_date_active        -- �K�p�J�n��
            );        
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
    -- =============================
    -- �X�V�f�[�^�擾
    -- =============================
    <<xdci_upd_data_loop>>
    FOR xdci_upd_dat IN get_upd_data_cur LOOP
      -- �^���A�h�I���}�X�^I/F���R�[�h�^�Ƀf�[�^���Z�b�g����
      lr_xdci_if_data.p_b_classe
          := xdci_upd_dat.p_b_classe;               -- �x�������敪
      lr_xdci_if_data.goods_classe
          := xdci_upd_dat.goods_classe;             -- ���i�敪
      lr_xdci_if_data.delivery_company_code
          := xdci_upd_dat.delivery_company_code;    -- �^���Ǝ�
      lr_xdci_if_data.shipping_address_classe
          := xdci_upd_dat.shipping_address_classe;  -- �z���敪
      lr_xdci_if_data.delivery_distance
          := xdci_upd_dat.delivery_distance;        -- �^������
      lr_xdci_if_data.delivery_weight
          := xdci_upd_dat.delivery_weight;          -- �d��
      lr_xdci_if_data.start_date_active
          := xdci_upd_dat.start_date_active;        -- �K�p�J�n��
      lr_xdci_if_data.shipping_expenses
          := xdci_upd_dat.shipping_expenses;        -- �^����
      lr_xdci_if_data.leaf_consolid_add
          := xdci_upd_dat.leaf_consolid_add;        -- ���[�t���ڊ���
--    
      -- ===============================
      -- �f�[�^�_���v�擾����
      -- ===============================
      get_data_dump(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
        , ov_dump    => lv_dump                           -- �f�[�^�_���v������
        , ov_errbuf  => lv_errbuf                         -- �G���[�E���b�Z�[�W           # �Œ� #
        , ov_retcode => lv_retcode                        -- ���^�[���E�R�[�h             # �Œ� #
        , ov_errmsg  => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- E-5.�}�X�^�f�[�^�`�F�b�N����
      -- =============================
      master_data_chk(
          ir_xxwip_delivery_charges_if  =>  lr_xdci_if_data -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
        , iv_dump                       =>  lv_dump         -- 2.�f�[�^�_���v
        , ov_errbuf                     =>  lv_errbuf       -- �G���[�E���b�Z�[�W           # �Œ� #
        , ov_retcode                    =>  lv_retcode      -- ���^�[���E�R�[�h             # �Œ� #
        , ov_errmsg                     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- OUT�p�����[�^���x���ɃZ�b�g
        ov_retcode := gv_status_warn;
--
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- ����̏ꍇ
      ELSE
        -- =============================
        -- E-8.�X�V�pPL/SQL�\����
        -- =============================
        set_upd_tab(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.�^���A�h�I���}�X�^I/F���R�[�h�^
         ,ov_errbuf  => lv_errbuf                         -- �G���[�E���b�Z�[�W           # �Œ� #
         ,ov_retcode => lv_retcode                        -- ���^�[���E�R�[�h             # �Œ� #
         ,ov_errmsg  => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        -- ����̏ꍇ
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- ����f�[�^����
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- ����f�[�^�_���vPL/SQL�\����
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
--
      END IF;
--
    END LOOP xdci_upd_data_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (get_upd_data_cur%ISOPEN) THEN
        CLOSE get_upd_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_upd_data_cur%ISOPEN) THEN
        CLOSE get_upd_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_upd_data_cur%ISOPEN) THEN
        CLOSE get_upd_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : �ꊇ�o�^����(E-9)
   ***********************************************************************************/
  PROCEDURE ins_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �ꊇ�o�^����
    -- ===============================
    FORALL ln_cnt IN 1..delivery_charges_id_ins_tab.COUNT
      INSERT INTO xxwip_delivery_charges(
          delivery_charges_id                         -- �^���}�X�^ID
        , p_b_classe                                  -- �x�������敪
        , goods_classe                                -- ���i�敪
        , delivery_company_code                       -- �^���Ǝ�
        , shipping_address_classe                     -- �z���敪
        , delivery_distance                           -- �^������
        , delivery_weight                             -- �d��
        , start_date_active                           -- �K�p�J�n��
        , shipping_expenses                           -- �^����
        , leaf_consolid_add                           -- ���[�t���ڊ���
        , created_by                                  -- �쐬��
        , creation_date                               -- �쐬��
        , last_updated_by                             -- �ŏI�X�V��
        , last_update_date                            -- �ŏI�X�V��
        , last_update_login                           -- �ŏI�X�V���O�C��
        , request_id                                  -- �v��ID
        , program_application_id                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                  -- �R���J�����g�E�v���O����ID
        , program_update_date                         -- �v���O�����X�V��
      ) VALUES (
          delivery_charges_id_ins_tab(ln_cnt)         -- �^���}�X�^ID
        , p_b_classe_ins_tab(ln_cnt)                  -- �x�������敪
        , goods_classe_ins_tab(ln_cnt)                -- ���i�敪
        , delivery_company_code_ins_tab(ln_cnt)       -- �^���Ǝ�
        , ship_address_classe_ins_tab(ln_cnt)         -- �z���敪
        , delivery_distance_ins_tab(ln_cnt)           -- �^������
        , delivery_weight_ins_tab(ln_cnt)             -- �d��
        , start_date_active_ins_tab(ln_cnt)           -- �K�p�J�n��
        , NVL(shipping_expenses_ins_tab(ln_cnt), 0)   -- �^����
        , NVL(leaf_consolid_add_ins_tab(ln_cnt), 0)   -- ���[�t���ڊ���
        , FND_GLOBAL.USER_ID                          -- �쐬��
        , SYSDATE                                     -- �쐬��
        , FND_GLOBAL.USER_ID                          -- �ŏI�X�V��
        , SYSDATE                                     -- �ŏI�X�V��
        , FND_GLOBAL.LOGIN_ID                         -- �ŏI�X�V���O�C��
        , FND_GLOBAL.CONC_REQUEST_ID                  -- �v��ID
        , FND_GLOBAL.PROG_APPL_ID                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , FND_GLOBAL.CONC_PROGRAM_ID                  -- �R���J�����g�E�v���O����ID
        , SYSDATE                                     -- �v���O�����X�V��
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
   * Procedure Name   : upd_table_batch
   * Description      : �ꊇ�X�V����(E-10)
   ***********************************************************************************/
  PROCEDURE upd_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- �ꊇ�X�V����
    -- ===============================
    FORALL ln_cnt IN 1..p_b_classe_upd_tab.COUNT
      UPDATE  xxwip_delivery_charges
        SET   shipping_expenses       = NVL(shipping_expenses_upd_tab(ln_cnt), 0)
                                        -- �^����
          ,   leaf_consolid_add       = NVL(leaf_consolid_add_upd_tab(ln_cnt), 0)
                                        -- ���[�t���ڊ���
-- 2009/04/03 v1.2 ADD START
          ,   change_flg              = gv_on
                                        -- �ύX�t���O
-- 2009/04/03 v1.2 ADD END
          ,   last_updated_by         = FND_GLOBAL.USER_ID
                                        -- �ŏI�X�V��
          ,   last_update_date        = SYSDATE
                                        -- �ŏI�X�V��
          ,   last_update_login       = FND_GLOBAL.LOGIN_ID
                                        -- �ŏI�X�V���O�C��
          ,   request_id              = FND_GLOBAL.CONC_REQUEST_ID
                                        -- �v��ID
          ,   program_application_id  = FND_GLOBAL.PROG_APPL_ID
                                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,   program_id              = FND_GLOBAL.CONC_PROGRAM_ID
                                        -- �R���J�����g�E�v���O����ID
          ,   program_update_date     = SYSDATE
                                        -- �v���O�����X�V��
      WHERE   p_b_classe              = p_b_classe_upd_tab(ln_cnt)
                                        -- �x�������敪
        AND   goods_classe            = goods_classe_upd_tab(ln_cnt)
                                        -- ���i�敪
        AND   delivery_company_code   = delivery_company_code_upd_tab(ln_cnt)
                                        -- �^���Ǝ�
        AND   shipping_address_classe = ship_address_classe_upd_tab(ln_cnt)
                                        -- �z���敪
        AND   delivery_distance       = delivery_distance_upd_tab(ln_cnt)
                                        -- �^������
        AND   delivery_weight         = delivery_weight_upd_tab(ln_cnt)
                                        -- �d��
        AND   start_date_active       = start_date_active_upd_tab(ln_cnt)
                                        -- �K�p�J�n��
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
  END upd_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : upd_end_date_active_all
   * Description      : �K�p�I�����X�V����(E-11)
   ***********************************************************************************/
  PROCEDURE upd_end_date_active_all(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_end_date_active_all'; -- �v���O������
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
    cv_xxcmn_max_date       CONSTANT VARCHAR2(50) := 'XXCMN_MAX_DATE';  -- PROFILE_OPTION�FMAX���t
    cv_xxcmn_max_date_name  CONSTANT VARCHAR2(50) := 'XXCMN:MAX���t';   -- PROFILE_OPTION�FMAX���t
--
    -- *** ���[�J���ϐ� ***
    lt_max_date   fnd_profile_option_values.profile_option_value%TYPE;  -- MAX���t
    ld_max_date   DATE;                                                 -- �ϊ���MAX���t
    ln_count      NUMBER DEFAULT 0;                                     -- �����J�E���g
--
    -- ��r�p�ϐ�
    lt_pre_p_b_classe               xxwip_delivery_charges.p_b_classe%TYPE;          -- �x�������敪
    lt_pre_goods_classe             xxwip_delivery_charges.goods_classe%TYPE;            -- ���i�敪
    lt_pre_delivery_company_code    xxwip_delivery_charges.delivery_company_code%TYPE;   -- �^���Ǝ�
    lt_pre_shipping_address_classe  xxwip_delivery_charges.shipping_address_classe%TYPE; -- �z���敪
    lt_pre_delivery_distance        xxwip_delivery_charges.delivery_distance%TYPE;       -- �^������
    lt_pre_delivery_weight          xxwip_delivery_charges.delivery_weight%TYPE;         -- �d��
    lt_pre_start_date_active        xxwip_delivery_charges.start_date_active%TYPE;   -- �K�p�J�n��
    lt_pre_end_date_active          xxwip_delivery_charges.end_date_active%TYPE;     -- �K�p�I����
--
    -- �X�V�pPL/SQL�\
    p_b_classe_tab                  p_b_classe_ttype;                   -- �x�������敪
    goods_classe_tab                goods_classe_ttype;                 -- ���i�敪
    delivery_company_code_tab       delivery_company_code_ttype;        -- �^���Ǝ�
    ship_address_classe_tab         shipping_address_classe_ttype;      -- �z���敪
    delivery_distance_tab           delivery_distance_ttype;            -- �^������
    delivery_weight_tab             delivery_weight_ttype;              -- �d��
    start_date_active_tab           start_date_active_ttype;            -- �K�p�J�n��
    end_date_active_tab             end_date_active_ttype;              -- �K�p�I����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �^���A�h�I���}�X�^
    CURSOR upd_end_date_cur IS
      SELECT  xdc.p_b_classe              -- �x�������敪
          ,   xdc.goods_classe            -- ���i�敪
          ,   xdc.delivery_company_code   -- �^���Ǝ�
          ,   xdc.shipping_address_classe -- �z���敪
          ,   xdc.delivery_distance       -- �^������
          ,   xdc.delivery_weight         -- �d��
          ,   xdc.start_date_active       -- �K�p�J�n��
          ,   xdc.end_date_active         -- �K�p�I����
      FROM    xxwip_delivery_charges xdc  -- �^���A�h�I���}�X�^
-- v1.3 ADD START
      WHERE   xdc.goods_classe = gv_prod_div -- ���i�敪
-- v1.3 ADD END
      ORDER BY
              p_b_classe                  -- �x�������敪
          ,   goods_classe                -- ���i�敪
          ,   delivery_company_code       -- �^���Ǝ�
          ,   shipping_address_classe     -- �z���敪
          ,   delivery_distance           -- �^������
          ,   delivery_weight             -- �d��
          ,   start_date_active           -- �K�p�J�n��
      ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_xxwip_delivery_charges   upd_end_date_cur%ROWTYPE;
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
    -- MAX���t�擾
    -- ===============================
    lt_max_date :=  FND_PROFILE.VALUE(cv_xxcmn_max_date);
--
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lt_max_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- ���W���[�������́FXXCMN ����
                   ,gv_msg_xxcmn10002      -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                   ,gv_tkn_ng_profile      -- �g�[�N���FNG�v���t�@�C����
                   ,cv_xxcmn_max_date_name -- MAX���t
                   ),1,5000);
--
      RAISE global_api_expt;
    END IF;
--
    -- MAX���t��DATE�^�ɕϊ�
    ld_max_date :=  FND_DATE.STRING_TO_DATE(lt_max_date, 'YYYY/MM/DD');
--
    -- �ϊ��ł��Ȃ������ꍇ�̓G���[
    IF (ld_max_date IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �J�[�\���I�[�v��
    -- ===============================
    OPEN upd_end_date_cur;
    FETCH upd_end_date_cur INTO lr_xxwip_delivery_charges;
--
    IF (upd_end_date_cur%FOUND) THEN
      -- ��r�p�ϐ��ɒl���Z�b�g
      lt_pre_p_b_classe               := lr_xxwip_delivery_charges.p_b_classe;      -- �x�������敪
      lt_pre_goods_classe             := lr_xxwip_delivery_charges.goods_classe;    -- ���i�敪
      lt_pre_delivery_company_code    := lr_xxwip_delivery_charges.delivery_company_code;   
                                                                                    -- �^���Ǝ�
      lt_pre_shipping_address_classe  := lr_xxwip_delivery_charges.shipping_address_classe; 
                                                                                    -- �z���敪
      lt_pre_delivery_distance        := lr_xxwip_delivery_charges.delivery_distance;
                                                                                    -- �^������
      lt_pre_delivery_weight          := lr_xxwip_delivery_charges.delivery_weight; -- �d��
      lt_pre_start_date_active        := lr_xxwip_delivery_charges.start_date_active;
                                                                                    -- �K�p�J�n��
      lt_pre_end_date_active          := lr_xxwip_delivery_charges.end_date_active; -- �K�p�I����
--
      <<upd_end_date_loop>>
      LOOP
        -- ���R�[�h�Ǎ�
        FETCH upd_end_date_cur INTO lr_xxwip_delivery_charges;
        EXIT WHEN upd_end_date_cur%NOTFOUND;
--
        -- ===============================
        -- �O��Ǎ��f�[�^�Ɣ�r
        -- ===============================
        -- �قȂ�ꍇ(�L�[�u���C�N��)
        IF    (lt_pre_p_b_classe              <> lr_xxwip_delivery_charges.p_b_classe)
                                                  -- �x�������敪
          OR  (lt_pre_goods_classe            <> lr_xxwip_delivery_charges.goods_classe)
                                                  -- ���i�敪
          OR  (lt_pre_delivery_company_code   <> lr_xxwip_delivery_charges.delivery_company_code)
                                                  -- �^���Ǝ�
          OR  (lt_pre_shipping_address_classe <> lr_xxwip_delivery_charges.shipping_address_classe)
                                                  -- �z���敪
          OR  (lt_pre_delivery_distance       <> lr_xxwip_delivery_charges.delivery_distance) 
                                                  -- �^������
          OR  (lt_pre_delivery_weight         <> lr_xxwip_delivery_charges.delivery_weight)
                                                  -- �d��
        THEN
          -- �O��Ǎ��f�[�^�̓K�p�I�������K���łȂ��ꍇ
          IF  ((lt_pre_end_date_active IS NULL)
            OR  (lt_pre_end_date_active <> ld_max_date))
          THEN
            ln_count  :=  ln_count + 1;
            -- �O��Ǎ��f�[�^���X�V�pPL/SQL�\�ɃZ�b�g����
            p_b_classe_tab(ln_count)            := lt_pre_p_b_classe;               -- �x�������敪
            goods_classe_tab(ln_count)          := lt_pre_goods_classe;             -- ���i�敪
            delivery_company_code_tab(ln_count) := lt_pre_delivery_company_code;    -- �^���Ǝ�
            ship_address_classe_tab(ln_count)   := lt_pre_shipping_address_classe;  -- �z���敪
            delivery_distance_tab(ln_count)     := lt_pre_delivery_distance;        -- �^������
            delivery_weight_tab(ln_count)       := lt_pre_delivery_weight;          -- �d��
            start_date_active_tab(ln_count)     := lt_pre_start_date_active;        -- �K�p�J�n��
            end_date_active_tab(ln_count)       := ld_max_date;              -- �K�p�I����(MAX���t)
--
          END IF;
--
        ELSE
--
          -- �L�[�u���C�N���Ȃ��ꍇ�ŁA�K�p�I�������K���łȂ��ꍇ�A
          -- �����R�[�h�̓K�p�J�n��-1�����Z�b�g����
          IF  ((lt_pre_end_date_active IS NULL)
            OR  (lt_pre_end_date_active <> lr_xxwip_delivery_charges.start_date_active - 1))
          THEN
            ln_count  :=  ln_count + 1;
            -- �O��Ǎ��f�[�^���X�V�pPL/SQL�\�ɃZ�b�g����
            p_b_classe_tab(ln_count)
                := lt_pre_p_b_classe;                               -- �x�������敪
            goods_classe_tab(ln_count)
                := lt_pre_goods_classe;                             -- ���i�敪
            delivery_company_code_tab(ln_count)
                := lt_pre_delivery_company_code;                    -- �^���Ǝ�
            ship_address_classe_tab(ln_count)
                := lt_pre_shipping_address_classe;                  -- �z���敪
            delivery_distance_tab(ln_count)
                := lt_pre_delivery_distance;                        -- �^������
            delivery_weight_tab(ln_count)
                := lt_pre_delivery_weight;                          -- �d��
            start_date_active_tab(ln_count)
                := lt_pre_start_date_active;                        -- �K�p�J�n��
            end_date_active_tab(ln_count)
                := lr_xxwip_delivery_charges.start_date_active - 1; -- �K�p�J�n��-1��
--                 
          END IF;
--
        END IF;
--
        -- ��r�p�ϐ��Ɍ����R�[�h���Z�b�g
        lt_pre_p_b_classe               := lr_xxwip_delivery_charges.p_b_classe;
                                                                                    -- �x�������敪
        lt_pre_goods_classe             := lr_xxwip_delivery_charges.goods_classe;
                                                                                    -- ���i�敪
        lt_pre_delivery_company_code    := lr_xxwip_delivery_charges.delivery_company_code;   
                                                                                    -- �^���Ǝ�
        lt_pre_shipping_address_classe  := lr_xxwip_delivery_charges.shipping_address_classe; 
                                                                                    -- �z���敪
        lt_pre_delivery_distance        := lr_xxwip_delivery_charges.delivery_distance;       
                                                                                    -- �^������
        lt_pre_delivery_weight          := lr_xxwip_delivery_charges.delivery_weight;         
                                                                                    -- �d��
        lt_pre_start_date_active        := lr_xxwip_delivery_charges.start_date_active;
                                                                                    -- �K�p�J�n��
        lt_pre_end_date_active          := lr_xxwip_delivery_charges.end_date_active;
                                                                                    -- �K�p�I����
--
      END LOOP upd_end_date_loop;
--    
      -- ===============================
      -- �J�[�\���N���[�Y
      -- ===============================
      CLOSE upd_end_date_cur;
--
      -- =====================================
      -- �ŏI�Ǎ����R�[�h�̓K�p�I�������Z�b�g
      -- =====================================
      IF  ((lt_pre_end_date_active IS NULL)
        OR  (lt_pre_end_date_active <> ld_max_date))
      THEN
        ln_count  :=  ln_count + 1;
        -- �O��Ǎ��f�[�^���X�V�pPL/SQL�\�ɃZ�b�g����
        p_b_classe_tab(ln_count)
                  := lt_pre_p_b_classe;               -- �x�������敪
        goods_classe_tab(ln_count)
                  := lt_pre_goods_classe;             -- ���i�敪
        delivery_company_code_tab(ln_count)
                  := lt_pre_delivery_company_code;    -- �^���Ǝ�
        ship_address_classe_tab(ln_count)
                  := lt_pre_shipping_address_classe;  -- �z���敪
        delivery_distance_tab(ln_count)
                  := lt_pre_delivery_distance;        -- �^������
        delivery_weight_tab(ln_count)
                  := lt_pre_delivery_weight;          -- �d��
        start_date_active_tab(ln_count)
                  := lt_pre_start_date_active;        -- �K�p�J�n��
        end_date_active_tab(ln_count)
                  := ld_max_date;                     -- �K�p�I����(MAX���t)
--
      END IF;
--
      -- ===============================
      -- �ꊇ�X�V����
      -- ===============================
      FORALL ln_upd_cnt IN 1.. delivery_company_code_tab.COUNT  
        UPDATE  xxwip_delivery_charges xdc -- �^���A�h�I���}�X�^
          SET   end_date_active             = end_date_active_tab(ln_upd_cnt)
                                              -- �K�p�I����
-- 2009/04/03 v1.2 ADD START
            ,   change_flg                  = gv_on
                                              -- �ύX�t���O
-- 2009/04/03 v1.2 ADD END
            ,   last_updated_by             = FND_GLOBAL.USER_ID
                                              -- �ŏI�X�V��
            ,   last_update_date            = SYSDATE
                                              -- �ŏI�X�V��
            ,   last_update_login           = FND_GLOBAL.LOGIN_ID
                                              -- �ŏI�X�V���O�C��
            ,   request_id                  = FND_GLOBAL.CONC_REQUEST_ID
                                              -- �v��ID
            ,   program_application_id      = FND_GLOBAL.PROG_APPL_ID
                                              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,   program_id                  = FND_GLOBAL.CONC_PROGRAM_ID
                                              -- �R���J�����g�E�v���O����ID
            ,   program_update_date         = SYSDATE
                                              -- �v���O�����X�V��
        WHERE   xdc.p_b_classe              = p_b_classe_tab(ln_upd_cnt)            -- �x�������敪
          AND   xdc.goods_classe            = goods_classe_tab(ln_upd_cnt)          -- ���i�敪
          AND   xdc.delivery_company_code   = delivery_company_code_tab(ln_upd_cnt) -- �^���Ǝ�
          AND   xdc.shipping_address_classe = ship_address_classe_tab(ln_upd_cnt)   -- �z���敪
          AND   xdc.delivery_distance       = delivery_distance_tab(ln_upd_cnt)     -- �^������
          AND   xdc.delivery_weight         = delivery_weight_tab(ln_upd_cnt)       -- �d��
          AND   xdc.start_date_active       = start_date_active_tab(ln_upd_cnt)     -- �K�p�J�n��
        ;    
--
    ELSE
      -- �f�[�^�����݂��Ȃ��ꍇ�̓J�[�\�������
      -- ===============================
      -- �J�[�\���N���[�Y
      -- ===============================
      CLOSE upd_end_date_cur;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (upd_end_date_cur%ISOPEN) THEN
        CLOSE upd_end_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (upd_end_date_cur%ISOPEN) THEN
        CLOSE upd_end_date_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (upd_end_date_cur%ISOPEN) THEN
        CLOSE upd_end_date_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_end_date_active_all;
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : �f�[�^�폜����(E-12)
   ***********************************************************************************/
  PROCEDURE del_table_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �^���A�h�I���}�X�^�C���^�t�F�[�X�폜
    -- =====================================
    FORALL ln_count IN 1..request_id_tab.COUNT
      DELETE /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */             -- 2008/11/11 �����w�E#589 Add
      FROM xxwip_delivery_charges_if xdci          -- �^���A�h�I���}�X�^�C���^�t�F�[�X
      WHERE   xdci.request_id   = request_id_tab(ln_count)  -- �v��ID
-- v1.3 ADD START
        AND   xdci.goods_classe = gv_prod_div               -- ���i�敪
-- v1.3 ADD END
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
  END del_table_data;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_dump_msg'; -- �v���O������
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
    -- ===============================
    -- �f�[�^�_���v�ꊇ�o��
    -- ===============================
--
    IF (gn_normal_cnt > 0) THEN
--
      --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);

      -- �����f�[�^�i���o���j
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- ���W���[�������́FXXCMN ����
                  ,gv_msg_xxcmn00005      -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                  ),1,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
      -- ����f�[�^�_���v
      <<normal_dump_loop>>
      FOR loop_cnt IN 1..normal_dump_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,normal_dump_tab(loop_cnt));
      END LOOP normal_dump_loop;
--
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);

      -- �X�L�b�v�f�[�^�f�[�^�i���o���j
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- ���W���[�������́FXXCMN ����
                  ,gv_msg_xxcmn00007      -- ���b�Z�[�W�FAPP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
                  ),1,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
      -- �x���f�[�^�_���v
      <<warn_dump_loop>>
      FOR loop_cnt IN 1..warn_dump_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,warn_dump_tab(loop_cnt));
      END LOOP warn_dump_loop;
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
  END put_dump_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
-- v1.3 ADD START
    iv_prod_div   IN  VARCHAR2,     --   ���i�敪
-- v1.3 ADD END
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- <�J�[�\����>
    -- �v��ID�擾�J�[�\��
    CURSOR xdci_request_id_cur
    IS
      SELECT fcr.request_id
      FROM   fnd_concurrent_requests fcr                -- �R���J�����g�v��ID�e�[�u��
      WHERE  EXISTS (
               SELECT /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */       -- 2008/11/11 �����w�E#589 Add
                      'X'
               FROM   xxwip_delivery_charges_if xdci    -- �^���A�h�I���}�X�^�C���^�t�F�[�X
               WHERE  xdci.request_id   = fcr.request_id  -- �v��ID
-- v1.3 ADD START
               AND    xdci.goods_classe = gv_prod_div     -- ���i�敪
-- v1.3 ADD END
               AND    ROWNUM = 1
             )
      ORDER BY fcr.request_id                           -- �v��ID
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0; -- �Ώی���
    gn_normal_cnt := 0; -- ���팏��
    gn_error_cnt  := 0; -- �G���[����
    gn_warn_cnt   := 0; -- �X�L�b�v����
--
-- v1.3 ADD START
    -- ���̓p�����[�^.���i�敪���O���[�o���ϐ��Ɋi�[
    gv_prod_div   := iv_prod_div;
-- v1.3 ADD END
    -- ===============================
    -- E-1.�v��ID�擾����
    -- ===============================
    <<get_request_id_loop>>
    FOR lr_xdci_request_id IN xdci_request_id_cur
    LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1 ;
      request_id_tab(gn_request_id_cnt)  := lr_xdci_request_id.request_id;
    END LOOP get_request_id_loop;
--
    IF (gn_request_id_cnt >= 1) THEN
--
      -- ===============================
      -- E-2.�\���b�N�擾����
      -- ===============================
      get_lock(
        ov_errbuf     => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- ���b�N�擾�G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ==================================
      -- �擾�����v��ID�̃��R�[�h����������
      -- ==================================
      <<process_loop>>
      FOR loop_cnt IN 1..request_id_tab.COUNT LOOP
        -- �o�^�p�E�X�V�pPL/SQL�\�J�E���^������
        gn_ins_tab_cnt  :=  0;  -- �o�^�p
        gn_upd_tab_cnt  :=  0;  -- �X�V�p
--
        -- �o�^�pPL/SQL�\������
        delivery_charges_id_ins_tab.DELETE;     -- �^���}�X�^ID
        p_b_classe_ins_tab.DELETE;              -- �x�������敪
        goods_classe_ins_tab.DELETE;            -- ���i�敪
        delivery_company_code_ins_tab.DELETE;   -- �^���Ǝ�
        ship_address_classe_ins_tab.DELETE;     -- �z���敪
        delivery_distance_ins_tab.DELETE;       -- �^������
        delivery_weight_ins_tab.DELETE;         -- �d��
        start_date_active_ins_tab.DELETE;       -- �K�p�J�n��
        end_date_active_ins_tab.DELETE;         -- �K�p�I����
        shipping_expenses_ins_tab.DELETE;       -- �^����
        leaf_consolid_add_ins_tab.DELETE;       -- ���[�t���ڊ���
--
        -- �X�V�pPL/SQL�\������
        delivery_charges_id_upd_tab.DELETE;     -- �^���}�X�^ID
        p_b_classe_upd_tab.DELETE;              -- �x�������敪
        goods_classe_upd_tab.DELETE;            -- ���i�敪
        delivery_company_code_upd_tab.DELETE;   -- �^���Ǝ�
        ship_address_classe_upd_tab.DELETE;     -- �z���敪
        delivery_distance_upd_tab.DELETE;       -- �^������
        delivery_weight_upd_tab.DELETE;         -- �d��
        start_date_active_upd_tab.DELETE;       -- �K�p�J�n��
        end_date_active_upd_tab.DELETE;         -- �K�p�I����
        shipping_expenses_upd_tab.DELETE;       -- �^����
        leaf_consolid_add_upd_tab.DELETE;       -- ���[�t���ڊ���
--
      -- ===============================
      -- E-3.�d���f�[�^���O����
      -- ===============================
        del_duplication_data(
            it_request_id => request_id_tab(loop_cnt) -- 1.�v��ID
          , ov_errbuf     => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );                 
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := gv_status_warn;
        END IF;
--
        -- ===============================
        -- E-4.�V�K�o�^�f�[�^�擾����
        -- ===============================
        get_ins_data(
            it_request_id => request_id_tab(loop_cnt) -- 1.�v��ID
          , ov_errbuf     => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := gv_status_warn;
        END IF;
--
        -- ===============================
        -- E-7.�X�V�f�[�^�擾����
        -- ===============================
        get_upd_data(
            it_request_id => request_id_tab(loop_cnt) -- 1.�v��ID
          , ov_errbuf     => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := gv_status_warn;
        END IF;
--
        -- ===============================
        -- E-9.�ꊇ�o�^����
        -- ===============================
        ins_table_batch(
            ov_errbuf     => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- E-10.�ꊇ�X�V����
        -- ===============================
        upd_table_batch(
            ov_errbuf     => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP process_loop;
--
      -- ===============================
      -- E-11.�K�p�I�����X�V����
      -- ===============================
      upd_end_date_active_all(
            ov_errbuf     => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- E-12.�f�[�^�폜����
      -- ===============================
      del_table_data(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �f�[�^�_���v�ꊇ�o�͏���
      -- ===============================
      put_dump_msg(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      -- �v��ID���擾�ł��Ȃ��ꍇ�͏������s��Ȃ��B
      NULL;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (xdci_request_id_cur%ISOPEN) THEN
        CLOSE xdci_request_id_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (xdci_request_id_cur%ISOPEN) THEN
        CLOSE xdci_request_id_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (xdci_request_id_cur%ISOPEN) THEN
        CLOSE xdci_request_id_cur;
      END IF;
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
    errbuf        OUT VARCHAR2, --   �G���[�E���b�Z�[�W  --# �Œ� #
-- v1.3 MOD START
--    retcode       OUT VARCHAR2  --   ���^�[���E�R�[�h    --# �Œ� #
    retcode       OUT VARCHAR2, --   ���^�[���E�R�[�h    --# �Œ� #
    iv_prod_div   IN  VARCHAR2  --   ���i�敪
-- v1.3 MOD END
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
-- v1.3 ADD START
      iv_prod_div, --   ���i�敪
-- v1.3 ADD END
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
END xxwip720002c;
/
