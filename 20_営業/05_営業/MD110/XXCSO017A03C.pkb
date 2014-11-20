CREATE OR REPLACE PACKAGE BODY XXCSO017A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO017A03C(body)
 * Description      : �̔���p���ϓ��͉�ʂ���A���ϔԍ��A�Ŗ��Ɍ��Ϗ���
 *                    ���[�ɏo�͂��܂��B
 * MD.050           : MD050_CSO_017_A03_���Ϗ��i�̔���p�jPDF�o��
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_param              �p�����[�^�E�`�F�b�N(A-1)
 *  process_data           ���H����(A-3)
 *  insert_row             ���[�N�e�[�u���o��(A-4)
 *  insert_blanks          ���[�N�e�[�u��(��s)�o��(A-5)
 *  act_svf                SVF�N��(A-6)
 *  delete_row             ���[�N�e�[�u���f�[�^�폜(A-7)
 *  submain                ���C�������v���V�[�W��
 *                           �f�[�^�擾(A-2)
 *                           SVF�N��API�G���[�`�F�b�N(A-8)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-09    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF�N��API���ߍ���
 *  2009-03-05    1.1   Kazuyo.Hosoi     ���[���C�A�E�g���r���[�w�E�Ή�
 *                                       (�X�֔ԍ��̎擾�AJAN�R�[�h�̕ҏW)
 *  2009-04-03    1.2   Kazuo.Satomura   �r�s��Q�Ή�(T1_0294)
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date   CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO017A03C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cn_org_id              CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ���O�C���g�D�h�c
  -- ���t����
  cv_format_date_ymd1    CONSTANT VARCHAR2(8)   := 'YYYYMMDD';      -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymd2    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';    -- ���t�t�H�[�}�b�g�i�N/��/���j
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496';  -- �p�����[�^�o��
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00005';  -- �K�{���ڃG���[
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00495';  -- �o�͏�񖢎擾�G���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042';  -- �c�a�o�^�E�X�V�G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- ���b�N�G���[���b�Z�[�W
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00417';  -- API�G���[���b�Z�[�W
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00503';  -- ����0�����b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_param_nm        CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_param1          CONSTANT VARCHAR2(20) := 'PARAM1';
  cv_tkn_act             CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_qt_num          CONSTANT VARCHAR2(20) := 'QUOTE_NUMBER';
  --
  cv_msg_prnthss_l       CONSTANT VARCHAR2(1)  := '(';
  cv_msg_prnthss_r       CONSTANT VARCHAR2(1)  := ')';
  cv_msg_comma           CONSTANT VARCHAR2(1)  := ',';
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_page_cnt            NUMBER DEFAULT 1;  -- ��s�o�͗p�y�[�W�J�E���^
  gn_rec_cnt             NUMBER DEFAULT 1;  -- ��s�o�͗p���R�[�h�J�E���^
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ϒ��[���[�N�e�[�u�� �f�[�^�i�[�p���R�[�h�^��`
  TYPE g_rp_qte_lst_data_rtype IS RECORD(
     quote_header_id               xxcso_rep_quote_list.quote_header_id%TYPE            -- ���σw�b�_�[�h�c
    ,line_order                    xxcso_rep_quote_list.line_order%TYPE                 -- ���я�
    ,quote_line_id                 xxcso_rep_quote_list.quote_line_id%TYPE              -- ���ϖ��ׂh�c 
    ,quote_number                  xxcso_rep_quote_list.quote_number%TYPE               -- ���ϔԍ�
    ,publish_date                  xxcso_rep_quote_list.publish_date%TYPE               -- ���s��
    ,customer_name                 xxcso_rep_quote_list.customer_name%TYPE              -- �ڋq��
    ,account_number                xxcso_quote_headers.account_number%TYPE              -- �ڋq�R�[�h
    ,deliv_place                   xxcso_rep_quote_list.deliv_place%TYPE                -- �[���ꏊ
    ,header_payment_condition      xxcso_rep_quote_list.header_payment_condition%TYPE   -- �w�b�_�[�x������
    ,base_code                     xxcso_quote_headers.base_code%TYPE                   -- ���_�R�[�h
    ,base_addr                     xxcso_rep_quote_list.base_addr%TYPE                  -- ���_�Z��
    ,base_name                     xxcso_rep_quote_list.base_name%TYPE                  -- ���_��
    ,base_phone_no                 xxcso_rep_quote_list.base_phone_no%TYPE              -- ���_�d�b�ԍ�
    ,unit_type                     xxcso_quote_headers.unit_type%TYPE                   -- �P���敪
    ,quote_submit_name             xxcso_quote_headers.quote_submit_name%TYPE           -- ���Ϗ���o�於
    ,quote_unit_sale               xxcso_rep_quote_list.quote_unit_sale%TYPE            -- ���ϒP��
    ,dliv_prce_tx_t                xxcso_quote_headers.deliv_price_tax_type%TYPE        -- �X�[���i�ŋ敪
    ,stre_prce_tx_t                xxcso_quote_headers.store_price_tax_type%TYPE        -- �������i�ŋ敪
    ,dliv_prce_tx_t_nm             xxcso_rep_quote_list.deliv_price_tax_type%TYPE       -- �X�[���i�ŋ敪��
    ,stre_prce_tx_t_nm             xxcso_rep_quote_list.store_price_tax_type%TYPE       -- �������i�ŋ敪��
    ,special_note                  xxcso_rep_quote_list.special_note%TYPE               -- ���L����
    ,inventory_item_id             xxcso_quote_lines.inventory_item_id%TYPE             -- �i�ڂh�c
    ,item_name                     xxcso_rep_quote_list.item_name%TYPE                  -- ���i��
    ,jan_code                      xxcso_rep_quote_list.jan_code%TYPE                   -- JAN�R�[�h
    ,standards                     xxcso_rep_quote_list.standard%TYPE                   -- �K�i
    ,inc_num                       xxcso_rep_quote_list.inc_num%TYPE                    -- ���� 
    ,sticer_price                  xxcso_rep_quote_list.sticer_price%TYPE               -- ���[�J�[��]�������i
    ,quote_div                     xxcso_quote_lines.quote_div%TYPE                     -- ���ϋ敪
    ,quote_div_nm                  xxcso_rep_quote_list.quote_div%TYPE                  -- ���ϋ敪��
    ,usually_deliv_price           xxcso_rep_quote_list.usually_deliv_price%TYPE        -- �ʏ�X�[���i
    ,usually_store_sale_price      xxcso_rep_quote_list.usually_store_sale_price%TYPE   -- �ʏ�X������
    ,this_time_deliv_price         xxcso_rep_quote_list.this_time_deliv_price%TYPE      -- ����X�[���i
    ,this_time_store_sale_price    xxcso_rep_quote_list.this_time_store_sale_price%TYPE -- ����X������
    ,quote_start_date              xxcso_rep_quote_list.quote_start_date%TYPE           -- ���ԁi�J�n�j
    ,quote_end_date                xxcso_rep_quote_list.quote_end_date%TYPE             -- ���ԁi�I���j
    ,remarks                       xxcso_rep_quote_list.remarks%TYPE                    -- ���l
    ,created_by                    xxcso_rep_quote_list.created_by%TYPE                 -- �쐬��
    ,creation_date                 xxcso_rep_quote_list.creation_date%TYPE              -- �쐬��
    ,last_updated_by               xxcso_rep_quote_list.last_updated_by%TYPE            -- �ŏI�X�V��
    ,last_update_date              xxcso_rep_quote_list.last_update_date%TYPE           -- �ŏI�X�V��
    ,last_update_login             xxcso_rep_quote_list.last_update_login%TYPE          -- �ŏI�X�V���O�C��
    ,request_id                    xxcso_rep_quote_list.request_id%TYPE                 -- �v���h�c        
    ,program_application_id        xxcso_rep_quote_list.program_application_id%TYPE     -- �ݶ�����۸��ѱ��ع����
    ,program_id                    xxcso_rep_quote_list.program_id%TYPE                 -- �ݶ�����۸��тh�c
    ,program_update_date           xxcso_rep_quote_list.program_update_date%TYPE        -- ��۸��эX�V��
  );
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�E�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
     in_qt_hdr_id        IN  NUMBER           -- ���σw�b�_�[ID
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���萔 ***
    cv_qt_hdr_id        CONSTANT VARCHAR2(100)   := '���σw�b�_�[�h�c';
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg              VARCHAR2(5000);
    -- *** ���[�J����O ***
    chk_param_expt   EXCEPTION;  -- ���σw�b�_�[�h�c�����̓G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �N���p�����[�^���b�Z�[�W�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_01      --���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_param_nm       --�g�[�N���R�[�h1
                ,iv_token_value1 => cv_qt_hdr_id          --�g�[�N���l1
                ,iv_token_name2  => cv_tkn_val            --�g�[�N���R�[�h2
                ,iv_token_value2 => TO_CHAR(in_qt_hdr_id) --�g�[�N���l2
              );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- ===========================
    -- �p�����[�^�K�{�`�F�b�N
    -- ===========================
    IF (in_qt_hdr_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_clmn           --�g�[�N���R�[�h1
                    ,iv_token_value1 => cv_qt_hdr_id          --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** ���σw�b�_�[�h�c�����̓G���[ ***
    WHEN chk_param_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : process_data
   * Description      : ���H����(A-3)
   ***********************************************************************************/
  PROCEDURE process_data(
     io_rp_qte_lst_dt_rec  IN OUT NOCOPY g_rp_qte_lst_data_rtype  -- ���σf�[�^
    ,ov_errbuf             OUT NOCOPY VARCHAR2                    -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2                    -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'process_data';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �N�C�b�N�R�[�h�擾
    cv_lkup_tp_tx_dvsn       CONSTANT VARCHAR2(30) := 'XXCSO1_TAX_DIVISION';
    cv_lkup_tp_unt_prc_dvsn  CONSTANT VARCHAR2(30) := 'XXCSO1_UNIT_PRICE_DIVISION';
    cv_lkup_tp_qte_dvsn      CONSTANT VARCHAR2(30) := 'XXCSO1_QUOTE_DIVISION';
    /* 2009.04.03 K.Satomura T1_0294�Ή� START */
    --cv_lkup_tp_itm_nt_um_cd  CONSTANT VARCHAR2(30) := 'XXINV_ITM_NET_UOM_CODE';
    cv_lkup_tp_itm_nt_um_cd  CONSTANT VARCHAR2(30) := 'XXCMM_ITM_NET_UOM_CODE';
    /* 2009.04.03 K.Satomura T1_0294�Ή� END */
    --
    cv_yes                   CONSTANT VARCHAR2(1)  := 'Y';
    cv_zero                  CONSTANT VARCHAR2(1)  := '0';
    cv_quote_div             CONSTANT VARCHAR2(1)  := '4';                  -- ���ϋ敪 4:��������(���ʔ̔�)
    cv_fmt                   CONSTANT VARCHAR2(7)  := 'FM9,999';            -- �K�i�ҏW�p�t�H�[�}�b�g
    cv_unit_type_hs          CONSTANT VARCHAR2(1)  := '1';                  -- �P���敪:1(�{��)
    cv_unit_type_cs          CONSTANT VARCHAR2(1)  := '2';                  -- �P���敪:2(C/S)
    cv_unit_type_bl          CONSTANT VARCHAR2(1)  := '3';                  -- �P���敪:3:�{�[��
    -- ���b�Z�[�W�o�͗p�g�[�N��
    cv_tkn_party_name        CONSTANT VARCHAR2(100) := '�ڋq��';
    cv_tkn_loc_info          CONSTANT VARCHAR2(100) := '���_���';
    cv_tkn_dlv_prc_tx_t_nm   CONSTANT VARCHAR2(100) := '�X�[���i�ŋ敪��';
    cv_tkn_str_prc_tx_t_nm   CONSTANT VARCHAR2(100) := '�������i�ŋ敪��';
    cv_tkn_unit_tp_nm        CONSTANT VARCHAR2(100) := '�P���敪��';
    cv_tkn_item_info         CONSTANT VARCHAR2(100) := '�i�ڏ��';
    cv_tkn_qt_div_nm         CONSTANT VARCHAR2(100) := '���ϋ敪��';
    cv_tkn_itm_nt_um_cd_nm   CONSTANT VARCHAR2(100) := '���e�ʒP�ʖ�';
    --
    cv_qt_line_id            CONSTANT VARCHAR2(100) := '���ׂh�c : ';
    cv_invntry_itm_id        CONSTANT VARCHAR2(100) := '�i�ڂh�c : ';
    cv_ln_ordr               CONSTANT VARCHAR2(100) := '���я� : ';
    --
    cv_jan                   CONSTANT VARCHAR2(100) := 'JAN ';              -- JAN�R�[�h�ҏW������
    cv_space                 CONSTANT VARCHAR2(100) := ' ';                 -- ���p�X�y�[�X
    -- *** ���[�J���ϐ� ***
    lt_party_name            xxcso_cust_accounts_v.party_name%TYPE;         -- �ڋq��
    lt_location_name         xxcso_locations_v2.location_name%TYPE;         -- ������
    lt_address_line1         xxcso_locations_v2.address_line1%TYPE;         -- �Z��
    lt_phone                 xxcso_locations_v2.phone%TYPE;                 -- �d�b�ԍ�
    ld_sysdate               DATE;
    lt_mean_dlv_prce_tx_tp   fnd_lookup_values_vl.meaning%TYPE;             -- �X�[���i�ŋ敪��
    lt_mean_str_prce_tx_tp   fnd_lookup_values_vl.meaning%TYPE;             -- �������i�ŋ敪��
    lt_mean_unit_tp          fnd_lookup_values_vl.meaning%TYPE;             -- �P���敪��
    lt_item_short_name       xxcso_inventory_items_v2.item_short_name%TYPE; -- ���i��
    lt_fixed_price_new       xxcso_inventory_items_v2.fixed_price_new%TYPE; -- ���[�J�[��]�������i
    lt_jan_code              xxcso_inventory_items_v2.jan_code%TYPE;        -- JAN�R�[�h
    lt_case_inc_num          xxcso_inventory_items_v2.case_inc_num%TYPE;    -- �P�[�X����
    lt_bowl_inc_num          xxcso_inventory_items_v2.bowl_inc_num%TYPE;    -- �{�[������
    lv_qt_div_nm             VARCHAR2(240);                                 -- ���ϋ敪��
    lt_nets                  xxcso_inventory_items_v2.nets%TYPE;            -- ���e��
    lt_nets_uom_code         xxcso_inventory_items_v2.nets_uom_code%TYPE;   -- ���e�ʒP��
    lt_nets_uom_cd_nm        fnd_lookup_values_vl.meaning%TYPE;             -- ���e�ʒP�ʖ�
    lt_zip                   xxcso_locations_v2.zip%TYPE;                   -- �X�֔ԍ�
    -- ���b�Z�[�W�i�[�p
    lv_msg                   VARCHAR2(5000);
    -- �x�����b�Z�[�W�o�͔��f�t���O
    lv_msg_flg               BOOLEAN DEFAULT FALSE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �V�X�e�����t��ҏW���A�i�[
    ld_sysdate := TRUNC(SYSDATE);
--
    -- ===========================
    -- �ڋq���擾
    -- ===========================
    BEGIN
      SELECT xcav.party_name  party_name  -- �ڋq��
      INTO   lt_party_name
      FROM   xxcso_cust_accounts_v  xcav  -- �ڋq�}�X�^�r���[
      WHERE  xcav.account_number = io_rp_qte_lst_dt_rec.account_number;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03      --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1         --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_party_name     --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- ���_���E���_�Z���E���_�d�b�ԍ��擾
    -- ====================================
    BEGIN
      SELECT  xlv2.location_name  location_name  -- ������
             ,xlv2.address_line1  address_line1  -- �Z��
             ,xlv2.phone          phone          -- �d�b�ԍ�
             ,xlv2.zip            zip            -- �X�֔ԍ�
      INTO    lt_location_name
             ,lt_address_line1
             ,lt_phone
             ,lt_zip
      FROM   xxcso_locations_v2 xlv2  -- ���Ə��}�X�^(�ŐV)�r���[
      WHERE  xlv2.dept_code = io_rp_qte_lst_dt_rec.base_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03      --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1         --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_loc_info       --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- �X�[���i�ŋ敪���擾
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning       -- ���e(�X�[���i�ŋ敪��)
      INTO   lt_mean_dlv_prce_tx_tp
      FROM   fnd_lookup_values_vl flvv   -- �N�C�b�N�R�[�h
      WHERE  flvv.lookup_type   = cv_lkup_tp_tx_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = io_rp_qte_lst_dt_rec.dliv_prce_tx_t;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_dlv_prc_tx_t_nm  --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- �������i�ŋ敪���擾
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning       -- ���e(�������i�ŋ敪��)
      INTO   lt_mean_str_prce_tx_tp
      FROM   fnd_lookup_values_vl flvv   -- �N�C�b�N�R�[�h
      WHERE  flvv.lookup_type   = cv_lkup_tp_tx_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = io_rp_qte_lst_dt_rec.stre_prce_tx_t;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_str_prc_tx_t_nm  --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- �P���敪���擾
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning       -- ���e(�P���敪��)
      INTO   lt_mean_unit_tp
      FROM   fnd_lookup_values_vl flvv   -- �N�C�b�N�R�[�h
      WHERE  flvv.lookup_type   = cv_lkup_tp_unt_prc_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = io_rp_qte_lst_dt_rec.unit_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_unit_tp_nm       --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- �i�ڏ��擾
    -- ====================================
    BEGIN
      SELECT  xiiv2.item_short_name   item_short_name -- �i���E����
             ,xiiv2.nets              nets            -- ���e��
             ,xiiv2.nets_uom_code     nets_uom_code   -- ���e�ʒP��
             ,xiiv2.fixed_price_new   fixed_price_new -- �艿
             ,xiiv2.jan_code          jan_code        -- JAN�R�[�h
             ,xiiv2.case_inc_num      case_inc_num    -- �P�[�X����
             ,xiiv2.bowl_inc_num      bowl_inc_num    -- �{�[������
      INTO   lt_item_short_name
             ,lt_nets
             ,lt_nets_uom_code
             ,lt_fixed_price_new
             ,lt_jan_code
             ,lt_case_inc_num
             ,lt_bowl_inc_num
      FROM   xxcso_inventory_items_v2 xiiv2  -- �i�ڃ}�X�^(�ŐV)�r���[
      WHERE  xiiv2.inventory_item_id = io_rp_qte_lst_dt_rec.inventory_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_item_info        --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg        ||cv_msg_prnthss_l||
                    cv_qt_line_id ||TO_CHAR(io_rp_qte_lst_dt_rec.quote_line_id)       ||cv_msg_comma||
                    cv_invntry_itm_id||TO_CHAR(io_rp_qte_lst_dt_rec.inventory_item_id)||cv_msg_comma||
                    cv_ln_ordr       ||TO_CHAR(io_rp_qte_lst_dt_rec.line_order)       ||cv_msg_prnthss_r
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- ���ϋ敪���擾
    -- ====================================
    BEGIN
      SELECT DECODE(io_rp_qte_lst_dt_rec.quote_div
                    ,cv_quote_div, flvv.description
                    ,flvv.meaning
                    )  qt_div_nm         -- ���ϋ敪��
      INTO   lv_qt_div_nm
      FROM   fnd_lookup_values_vl flvv   -- �N�C�b�N�R�[�h
      WHERE  flvv.lookup_type   = cv_lkup_tp_qte_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = io_rp_qte_lst_dt_rec.quote_div;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_qt_div_nm        --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg        ||cv_msg_prnthss_l||
                    cv_qt_line_id ||TO_CHAR(io_rp_qte_lst_dt_rec.quote_line_id)       ||cv_msg_comma||
                    cv_invntry_itm_id||TO_CHAR(io_rp_qte_lst_dt_rec.inventory_item_id)||cv_msg_comma||
                    cv_ln_ordr       ||TO_CHAR(io_rp_qte_lst_dt_rec.line_order)       ||cv_msg_prnthss_r
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- ���e�ʒP�ʖ��擾
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning       -- ���e(���e�ʒP�ʖ�)
      INTO   lt_nets_uom_cd_nm
      FROM   fnd_lookup_values_vl flvv   -- �N�C�b�N�R�[�h
     WHERE  flvv.lookup_type   = cv_lkup_tp_itm_nt_um_cd
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = lt_nets_uom_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_03        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_param1           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_itm_nt_um_cd_nm  --�g�[�N���l1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg        ||cv_msg_prnthss_l||
                    cv_qt_line_id ||TO_CHAR(io_rp_qte_lst_dt_rec.quote_line_id)       ||cv_msg_comma||
                    cv_invntry_itm_id||TO_CHAR(io_rp_qte_lst_dt_rec.inventory_item_id)||cv_msg_comma||
                    cv_ln_ordr       ||TO_CHAR(io_rp_qte_lst_dt_rec.line_order)       ||cv_msg_prnthss_r
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- �擾�l��OUT�p�����[�^�ɐݒ�
    -- ====================================
    io_rp_qte_lst_dt_rec.customer_name     := NVL(io_rp_qte_lst_dt_rec.quote_submit_name,
                                                lt_party_name);                              -- �ڋq��
    io_rp_qte_lst_dt_rec.base_addr         := lt_zip || cv_space || lt_address_line1;        -- ���_�Z��
    io_rp_qte_lst_dt_rec.base_name         := lt_location_name;                              -- ���_��
    io_rp_qte_lst_dt_rec.base_phone_no     := lt_phone;                                      -- ���_�d�b�ԍ�
    io_rp_qte_lst_dt_rec.quote_unit_sale   := lt_mean_unit_tp;                               -- ���ϒP��
    io_rp_qte_lst_dt_rec.dliv_prce_tx_t_nm := lt_mean_dlv_prce_tx_tp;                        -- �X�[���i�ŋ敪��
    io_rp_qte_lst_dt_rec.stre_prce_tx_t_nm := lt_mean_str_prce_tx_tp;                        -- �������i�ŋ敪��
    io_rp_qte_lst_dt_rec.item_name         := lt_item_short_name;                            -- ���i��
    IF (lt_jan_code IS NULL) THEN
      io_rp_qte_lst_dt_rec.jan_code        := NULL;
    ELSE
      io_rp_qte_lst_dt_rec.jan_code        := cv_jan || SUBSTRB(lt_jan_code, 1, 7) ||
                                                cv_space || SUBSTRB(lt_jan_code, 8, 6);      -- JAN�R�[�h
    END IF;
    io_rp_qte_lst_dt_rec.standards         := TO_CHAR(lt_nets, cv_fmt) || lt_nets_uom_cd_nm; -- �K�i
    IF io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_hs THEN
      io_rp_qte_lst_dt_rec.inc_num         := NVL(lt_case_inc_num, cv_zero);
    ELSIF io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_cs THEN
      io_rp_qte_lst_dt_rec.inc_num         := NVL(lt_case_inc_num, cv_zero);
    ELSIF io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_bl THEN
      io_rp_qte_lst_dt_rec.inc_num         := NVL(TO_CHAR(lt_bowl_inc_num), cv_zero);
    END IF;                                                                                  -- ����
    io_rp_qte_lst_dt_rec.sticer_price      := NVL(lt_fixed_price_new, cv_zero);              -- ���[�J�[��]�������i
    io_rp_qte_lst_dt_rec.quote_div_nm      := lv_qt_div_nm;                                  -- ���ϋ敪��
--
    -- ��s�̑}��
    IF ov_retcode = cv_status_warn THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END process_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ���[�N�e�[�u���o��(A-4)
   ***********************************************************************************/
  PROCEDURE insert_row(
     i_rp_qte_lst_data_rec  IN  g_rp_qte_lst_data_rtype  -- ���σf�[�^
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- �v���O������
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '���ϒ��[���[�N�e�[�u���̓o�^';
    -- *** ���[�J����O ***
    insert_row_expt     EXCEPTION;          -- ���[�N�e�[�u���o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- ���[�N�e�[�u���o��
      INSERT INTO xxcso_rep_quote_list
        ( quote_work_id                -- ���ϒ��[���[�N�e�[�u���h�c
         ,quote_header_id              -- ���σw�b�_�[�h�c
         ,line_order                   -- ���я�
         ,quote_line_id                -- ���ϖ��ׂh�c 
         ,quote_number                 -- ���ϔԍ�
         ,publish_date                 -- ���s��
         ,customer_name                -- �ڋq��
         ,deliv_place                  -- �[���ꏊ
         ,header_payment_condition     -- �w�b�_�[�x������
         ,base_addr                    -- ���_�Z��
         ,base_name                    -- ���_��
         ,base_phone_no                -- ���_�d�b�ԍ�
         ,quote_unit_sale              -- ���ϒP��
         ,deliv_price_tax_type         -- �X�[���i�ŋ敪
         ,store_price_tax_type         -- �������i�ŋ敪
         ,special_note                 -- ���L����
         ,item_name                    -- ���i��
         ,jan_code                     -- JAN�R�[�h
         ,standard                     -- �K�i
         ,inc_num                      -- ���� 
         ,sticer_price                 -- ���[�J�[��]�������i
         ,quote_div                    -- ���ϋ敪��
         ,usually_deliv_price          -- �ʏ�X�[���i
         ,usually_store_sale_price     -- �ʏ�X������
         ,this_time_deliv_price        -- ����X�[���i
         ,this_time_store_sale_price   -- ����X������
         ,quote_start_date             -- ���ԁi�J�n�j
         ,quote_end_date               -- ���ԁi�I���j
         ,remarks                      -- ���l
         ,created_by                   -- �쐬��
         ,creation_date                -- �쐬��
         ,last_updated_by              -- �ŏI�X�V��
         ,last_update_date             -- �ŏI�X�V��
         ,last_update_login            -- �ŏI�X�V���O�C��
         ,request_id                   -- �v���h�c        
         ,program_application_id       -- �ݶ�����۸��ѱ��ع����
         ,program_id                   -- �ݶ�����۸��тh�c
         ,program_update_date          -- ��۸��эX�V��
        )
      VALUES
        ( xxcso_rep_quote_list_s01.NEXTVAL                     -- ���ϒ��[���[�N�e�[�u���h�c
         ,i_rp_qte_lst_data_rec.quote_header_id                -- ���σw�b�_�[�h�c
         ,i_rp_qte_lst_data_rec.line_order                     -- ���я�
         ,i_rp_qte_lst_data_rec.quote_line_id                  -- ���ϖ��ׂh�c
         ,i_rp_qte_lst_data_rec.quote_number                   -- ���ϔԍ�
         ,i_rp_qte_lst_data_rec.publish_date                   -- ���s��
         ,i_rp_qte_lst_data_rec.customer_name                  -- �ڋq��
         ,i_rp_qte_lst_data_rec.deliv_place                    -- �[���ꏊ
         ,i_rp_qte_lst_data_rec.header_payment_condition       -- �w�b�_�[�x������
         ,i_rp_qte_lst_data_rec.base_addr                      -- ���_�Z��
         ,i_rp_qte_lst_data_rec.base_name                      -- ���_��
         ,i_rp_qte_lst_data_rec.base_phone_no                  -- ���_�d�b�ԍ�
         ,i_rp_qte_lst_data_rec.quote_unit_sale                -- ���ϒP��
         ,i_rp_qte_lst_data_rec.dliv_prce_tx_t_nm              -- �X�[���i�ŋ敪��
         ,i_rp_qte_lst_data_rec.stre_prce_tx_t_nm              -- �������i�ŋ敪��
         ,i_rp_qte_lst_data_rec.special_note                   -- ���L����
         ,i_rp_qte_lst_data_rec.item_name                      -- ���i��
         ,i_rp_qte_lst_data_rec.jan_code                       -- JAN�R�[�h
         ,i_rp_qte_lst_data_rec.standards                      -- �K�i
         ,i_rp_qte_lst_data_rec.inc_num                        -- ����
         ,i_rp_qte_lst_data_rec.sticer_price                   -- ���[�J�[��]�������i
         ,i_rp_qte_lst_data_rec.quote_div_nm                   -- ���ϋ敪��
         ,i_rp_qte_lst_data_rec.usually_deliv_price            -- �ʏ�X�[���i
         ,i_rp_qte_lst_data_rec.usually_store_sale_price       -- �ʏ�X������
         ,i_rp_qte_lst_data_rec.this_time_deliv_price          -- ����X�[���i
         ,i_rp_qte_lst_data_rec.this_time_store_sale_price     -- ����X������
         ,i_rp_qte_lst_data_rec.quote_start_date               -- ���ԁi�J�n�j
         ,i_rp_qte_lst_data_rec.quote_end_date                 -- ���ԁi�I���j
         ,i_rp_qte_lst_data_rec.remarks                        -- ���l
         ,i_rp_qte_lst_data_rec.created_by                     -- �쐬��
         ,i_rp_qte_lst_data_rec.creation_date                  -- �쐬��
         ,i_rp_qte_lst_data_rec.last_updated_by                -- �ŏI�X�V��
         ,i_rp_qte_lst_data_rec.last_update_date               -- �ŏI�X�V��
         ,i_rp_qte_lst_data_rec.last_update_login              -- �ŏI�X�V���O�C��
         ,i_rp_qte_lst_data_rec.request_id                     -- �v���h�c
         ,i_rp_qte_lst_data_rec.program_application_id         -- �ݶ�����۸��ѱ��ع����
         ,i_rp_qte_lst_data_rec.program_id                     -- �ݶ�����۸��тh�c
         ,i_rp_qte_lst_data_rec.program_update_date            -- ��۸��эX�V��
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_04        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_act              --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_errmsg           --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ���[�N�e�[�u���o�͏�����O ***
    WHEN insert_row_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : insert_blanks
   * Description      : ���[�N�e�[�u��(��s)�o��(A-5)
   ***********************************************************************************/
  PROCEDURE insert_blanks(
     i_rp_qte_lst_data_rec  IN  g_rp_qte_lst_data_rtype  -- ���σf�[�^     
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_blanks';     -- �v���O������
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '���ϒ��[���[�N�e�[�u��(��s)�̓o�^';
    -- *** ���[�J����O ***
    insert_blanks_expt     EXCEPTION;          -- ���[�N�e�[�u���o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- ���[�N�e�[�u���o��
      INSERT INTO xxcso_rep_quote_list
        ( quote_work_id                -- ���ϒ��[���[�N�e�[�u���h�c
         ,quote_header_id              -- ���σw�b�_�[�h�c
         ,quote_line_id                -- ���ϖ��ׂh�c 
         ,quote_number                 -- ���ϔԍ�
         ,publish_date                 -- ���s��
         ,customer_name                -- �ڋq��
         ,deliv_place                  -- �[���ꏊ
         ,header_payment_condition     -- �w�b�_�[�x������
         ,base_addr                    -- ���_�Z��
         ,base_name                    -- ���_��
         ,base_phone_no                -- ���_�d�b�ԍ�
         ,quote_unit_sale              -- ���ϒP��
         ,deliv_price_tax_type         -- �X�[���i�ŋ敪
         ,store_price_tax_type         -- �������i�ŋ敪
         ,special_note                 -- ���L����
         ,created_by                   -- �쐬��
         ,creation_date                -- �쐬��
         ,last_updated_by              -- �ŏI�X�V��
         ,last_update_date             -- �ŏI�X�V��
         ,last_update_login            -- �ŏI�X�V���O�C��
         ,request_id                   -- �v���h�c        
         ,program_application_id       -- �ݶ�����۸��ѱ��ع����
         ,program_id                   -- �ݶ�����۸��тh�c
         ,program_update_date          -- ��۸��эX�V��
        )
      VALUES
        ( xxcso_rep_quote_list_s01.NEXTVAL                     -- ���ϒ��[���[�N�e�[�u���h�c
         ,i_rp_qte_lst_data_rec.quote_header_id                -- ���σw�b�_�[�h�c
         ,i_rp_qte_lst_data_rec.quote_line_id                  -- ���ϖ��ׂh�c
         ,i_rp_qte_lst_data_rec.quote_number                   -- ���ϔԍ�
         ,i_rp_qte_lst_data_rec.publish_date                   -- ���s��
         ,i_rp_qte_lst_data_rec.customer_name                  -- �ڋq��
         ,i_rp_qte_lst_data_rec.deliv_place                    -- �[���ꏊ
         ,i_rp_qte_lst_data_rec.header_payment_condition       -- �w�b�_�[�x������
         ,i_rp_qte_lst_data_rec.base_addr                      -- ���_�Z��
         ,i_rp_qte_lst_data_rec.base_name                      -- ���_��
         ,i_rp_qte_lst_data_rec.base_phone_no                  -- ���_�d�b�ԍ�
         ,i_rp_qte_lst_data_rec.quote_unit_sale                -- ���ϒP��
         ,i_rp_qte_lst_data_rec.dliv_prce_tx_t_nm              -- �X�[���i�ŋ敪��
         ,i_rp_qte_lst_data_rec.stre_prce_tx_t_nm              -- �������i�ŋ敪��
         ,i_rp_qte_lst_data_rec.special_note                   -- ���L����
         ,i_rp_qte_lst_data_rec.created_by                     -- �쐬��
         ,i_rp_qte_lst_data_rec.creation_date                  -- �쐬��
         ,i_rp_qte_lst_data_rec.last_updated_by                -- �ŏI�X�V��
         ,i_rp_qte_lst_data_rec.last_update_date               -- �ŏI�X�V��
         ,i_rp_qte_lst_data_rec.last_update_login              -- �ŏI�X�V���O�C��
         ,i_rp_qte_lst_data_rec.request_id                     -- �v���h�c
         ,i_rp_qte_lst_data_rec.program_application_id         -- �ݶ�����۸��ѱ��ع����
         ,i_rp_qte_lst_data_rec.program_id                     -- �ݶ�����۸��тh�c
         ,i_rp_qte_lst_data_rec.program_update_date            -- ��۸��эX�V��
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_04        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_act              --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_errmsg           --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_blanks_expt;
    END;
--
  EXCEPTION
    -- *** ���[�N�e�[�u���o�͏�����O ***
    WHEN insert_blanks_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_blanks;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF�N��(A-6)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'act_svf';     -- �v���O������
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF�N��';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO017A03S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO017A03S.vrq';  -- �N�G���[�l���t�@�C����
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';  
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- SVF�N������ 
    -- ======================
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd1)
                     || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
     ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
     ,iv_file_id      => lv_file_id            -- ���[ID
     ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
     ,iv_frm_file     => cv_svf_form_name      -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_svf_query_name     -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
     ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                  -- ������
     ,iv_printer_name => NULL                  -- �v�����^��
     ,iv_request_id   => cn_request_id         -- �v��ID
     ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
     );
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_06        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_api_nm           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --�g�[�N���l1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_row
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_row';     -- �v���O������
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '���ϒ��[���[�N�e�[�u��';
    -- *** ���[�J���ϐ� ***
    lt_quote_work_id      xxcso_rep_quote_list.quote_work_id%TYPE;  -- ���ϒ��[���[�N�e�[�u���h�c�i�[�p
    -- *** ���[�J����O ***
    tbl_lock_expt  EXCEPTION;  -- �e�[�u�����b�N�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==========================
    -- ���b�N�̊m�F
    -- ==========================
    BEGIN
      SELECT xrql.quote_work_id  quote_work_id  -- ���ϒ��[���[�N�e�[�u���h�c
      INTO   lt_quote_work_id
      FROM   xxcso_rep_quote_list  xrql         -- ���ϒ��[���[�N�e�[�u��
      WHERE  xrql.request_id = cn_request_id
        AND  ROWNUM = 1
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_05        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl              --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tkn_tbl_nm           --�g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg          --�g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                  );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE tbl_lock_expt;
    END;
    -- ==========================
    -- ���[�N�e�[�u���f�[�^�폜
    -- ==========================
    DELETE FROM xxcso_rep_quote_list xrql -- ���ϒ��[���[�N�e�[�u��
    WHERE xrql.request_id = cn_request_id;
--
  EXCEPTION
    -- *** �e�[�u�����b�N�G���[ ***
    WHEN tbl_lock_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_row;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     in_qt_hdr_id        IN  NUMBER            -- ���σw�b�_�[ID
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
    cb_true           CONSTANT BOOLEAN := TRUE;
    cv_tkn_qt_info    CONSTANT VARCHAR2(100) := '���Ϗ��';
    -- ��s�o�͏����p
    cn_page_cnt1      CONSTANT NUMBER  := 1;
    cn_rec_cnt1       CONSTANT NUMBER  := 1;
    cn_rec_cnt12      CONSTANT NUMBER  := 12;
    cn_rec_cnt13      CONSTANT NUMBER  := 13;
    cn_rec_cnt15      CONSTANT NUMBER  := 15;
    cn_rec_cnt19      CONSTANT NUMBER  := 19;
    cn_rec_cnt20      CONSTANT NUMBER  := 20;
    cn_rec_cnt21      CONSTANT NUMBER  := 21;
    cn_rec_cnt34      CONSTANT NUMBER  := 34;
    cn_rec_cnt40      CONSTANT NUMBER  := 40;
    -- IN,OUT�p�����[�^�i�[�p
    ln_qt_hdr_id      NUMBER;         -- IN�p�����[�^���σw�b�_�[�h�c
    -- *** ���[�J���ϐ� ***
    ln_ins_cnt        NUMBER DEFAULT 0;         -- �J�E���^
    ln_rec_num        NUMBER DEFAULT 0;         -- ��s�o�͗p���R�[�h�J�E���^�i�[�p
    ln_loop_cnt       NUMBER DEFAULT 0;         -- ��s�o�͗ploop�J�E���^
    lt_quote_number   xxcso_quote_headers.quote_number%TYPE; -- ���ϔԍ��i�[�p
    -- SVF�N��API�߂�l�i�[�p
    lv_errbuf_svf     VARCHAR2(5000);           -- �G���[�E���b�Z�[�W
    lv_retcode_svf    VARCHAR2(1);              -- ���^�[���E�R�[�h
    lv_errmsg_svf     VARCHAR2(5000);           -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���σf�[�^���o�J�[�\��
    CURSOR get_quote_data_cur
    IS
      SELECT  xqh.quote_header_id              quote_header_id           -- ���σw�b�_�[�h�c
              ,xqh.quote_number                quote_number              -- ���ϔԍ�
              ,xqh.publish_date                publish_date              -- ���s��
              ,xqh.account_number              account_number            -- �ڋq�R�[�h
              ,xqh.base_code                   base_code                 -- ���_�R�[�h
              ,xqh.deliv_place                 deliv_place               -- �[���ꏊ
              ,xqh.payment_condition           payment_condition         -- �x������
              ,xqh.special_note                special_note              -- ���L����
              ,xqh.deliv_price_tax_type        deliv_price_tax_type      -- �X�[���i�ŋ敪
              ,xqh.store_price_tax_type        store_price_tax_type      -- �������i�ŋ敪
              ,xqh.unit_type                   unit_type                 -- �P���敪
              ,xqh.quote_submit_name           quote_submit_name         -- ���Ϗ���o�於
              ,xql.quote_line_id               quote_line_id             -- ���ϖ��ׂh�c
              ,xql.inventory_item_id           inventory_item_id         -- �i�ڂh�c
              ,xql.quote_div                   quote_div                 -- ���ϋ敪
              ,xql.usually_deliv_price         usually_deliv_price       -- �ʏ�X�[���i
              ,xql.usually_store_sale_price    usually_store_sale_price  -- �ʏ�X������
              ,xql.this_time_deliv_price       this_time_deliv_price     -- ����X�[���i
              ,xql.this_time_store_sale_price  this_time_store_sale_price-- ����X�[����
              ,xql.quote_start_date            quote_start_date          -- ���ԁi�J�n�j
              ,xql.quote_end_date              quote_end_date            -- ���ԁi�I���j
              ,xql.remarks                     remarks                   -- ���l
              ,xql.line_order                  line_order                -- ���я�
      FROM  xxcso_quote_headers  xqh   -- ���σw�b�_�[�e�[�u��
           ,xxcso_quote_lines    xql   -- ���ϖ��׃e�[�u��
      WHERE  xqh.quote_header_id = ln_qt_hdr_id
        AND  xqh.quote_header_id = xql.quote_header_id
      ORDER BY  xql.line_order        -- ���я�
               ,xql.quote_line_id     -- ���ϖ��ׂh�c
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_get_quote_dt_rec     get_quote_data_cur%ROWTYPE;
    l_rp_qte_lst_data_rec  g_rp_qte_lst_data_rtype;
    -- *** ���[�J���E��O ***
    no_data_expt           EXCEPTION; -- �Ώۃf�[�^0����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �J�E���^�̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    ln_ins_cnt    := 0;
    -- IN�p�����[�^�i�[
    ln_qt_hdr_id := in_qt_hdr_id;  -- IN�p�����[�^���σw�b�_�[�h�c
--
    -- ========================================
    -- A-1.�p�����[�^�E�`�F�b�N
    -- ========================================
    chk_param(
      in_qt_hdr_id     => ln_qt_hdr_id        -- ���σw�b�_�[ID
     ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-2.�f�[�^�擾
    -- ========================================
    -- �J�[�\���I�[�v��
    OPEN get_quote_data_cur;
--
    <<get_quote_data_loop>>
    LOOP
      FETCH get_quote_data_cur INTO l_get_quote_dt_rec;
      -- �����Ώی����i�[
      gn_target_cnt := get_quote_data_cur%ROWCOUNT;
--
      -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
      EXIT WHEN get_quote_data_cur%NOTFOUND
      OR  get_quote_data_cur%ROWCOUNT = 0;
--
      -- ���R�[�h�ϐ�������
      l_rp_qte_lst_data_rec := NULL;
--
      -- �擾�f�[�^���i�[
      l_rp_qte_lst_data_rec.quote_header_id            := l_get_quote_dt_rec.quote_header_id;      -- ���σw�b�_�[�h�c
      l_rp_qte_lst_data_rec.line_order                 := l_get_quote_dt_rec.line_order;           -- ���я�
      l_rp_qte_lst_data_rec.quote_line_id              := l_get_quote_dt_rec.quote_line_id;        -- ���ϖ��ׂh�c
      l_rp_qte_lst_data_rec.quote_number               := l_get_quote_dt_rec.quote_number;         -- ���ϔԍ�
      l_rp_qte_lst_data_rec.publish_date               
        := TO_CHAR(l_get_quote_dt_rec.publish_date, cv_format_date_ymd1);     -- ���s��
      l_rp_qte_lst_data_rec.account_number             := l_get_quote_dt_rec.account_number;       -- �ڋq�R�[�h
      l_rp_qte_lst_data_rec.deliv_place                := l_get_quote_dt_rec.deliv_place;          -- �[���ꏊ
      l_rp_qte_lst_data_rec.header_payment_condition   := l_get_quote_dt_rec.payment_condition;    -- �w�b�_�[�x������
      l_rp_qte_lst_data_rec.base_code                  := l_get_quote_dt_rec.base_code;            -- ���_�R�[�h
      l_rp_qte_lst_data_rec.unit_type                  := l_get_quote_dt_rec.unit_type;            -- �P���敪
      l_rp_qte_lst_data_rec.quote_submit_name          := l_get_quote_dt_rec.quote_submit_name;    -- ���Ϗ���o�於
      l_rp_qte_lst_data_rec.dliv_prce_tx_t             := l_get_quote_dt_rec.deliv_price_tax_type; -- �X�[���i�ŋ敪
      l_rp_qte_lst_data_rec.stre_prce_tx_t             := l_get_quote_dt_rec.store_price_tax_type; -- �������i�ŋ敪
      l_rp_qte_lst_data_rec.special_note               := l_get_quote_dt_rec.special_note;         -- ���L����
      l_rp_qte_lst_data_rec.inventory_item_id          := l_get_quote_dt_rec.inventory_item_id;    -- �i�ڂh�c
      l_rp_qte_lst_data_rec.quote_div                  := l_get_quote_dt_rec.quote_div;            -- ���ϋ敪
      l_rp_qte_lst_data_rec.usually_deliv_price        := l_get_quote_dt_rec.usually_deliv_price;  -- �ʏ�X�[���i
      l_rp_qte_lst_data_rec.usually_store_sale_price   := l_get_quote_dt_rec.usually_store_sale_price;   -- �ʏ�X������
      l_rp_qte_lst_data_rec.this_time_deliv_price      := l_get_quote_dt_rec.this_time_deliv_price;      -- ����X�[���i
      l_rp_qte_lst_data_rec.this_time_store_sale_price := l_get_quote_dt_rec.this_time_store_sale_price; -- ����X������
      l_rp_qte_lst_data_rec.quote_start_date
        := TO_CHAR(l_get_quote_dt_rec.quote_start_date, cv_format_date_ymd2); -- ���ԁi�J�n�j
      l_rp_qte_lst_data_rec.quote_end_date
        := TO_CHAR(l_get_quote_dt_rec.quote_end_date, cv_format_date_ymd2);   -- ���ԁi�I���j
      l_rp_qte_lst_data_rec.remarks                    := l_get_quote_dt_rec.remarks;              -- ���l
      l_rp_qte_lst_data_rec.created_by                 := cn_created_by;                           -- �쐬��
      l_rp_qte_lst_data_rec.creation_date              := cd_creation_date;                        -- �쐬��
      l_rp_qte_lst_data_rec.last_updated_by            := cn_last_updated_by;                      -- �ŏI�X�V��
      l_rp_qte_lst_data_rec.last_update_date           := cd_last_update_date;                     -- �ŏI�X�V��
      l_rp_qte_lst_data_rec.last_update_login          := cn_last_update_login;                    -- �ŏI�X�V���O�C��
      l_rp_qte_lst_data_rec.request_id                 := cn_request_id;                           -- �v���h�c
      l_rp_qte_lst_data_rec.program_application_id     := cn_program_application_id;               -- �ݶ�����۸��ѱ��ع����
      l_rp_qte_lst_data_rec.program_id                 := cn_program_id;                           -- �ݶ�����۸��тh�c
      l_rp_qte_lst_data_rec.program_update_date        := cd_program_update_date;                  -- ��۸��эX�V��
--
      -- ========================================
      -- A-3.���H����
      -- ========================================
      process_data(
        io_rp_qte_lst_dt_rec   => l_rp_qte_lst_data_rec  -- ���σf�[�^
       ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_warn) THEN
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        -- ���^�[���R�[�h�Ɍx����ݒ�
        ov_retcode := cv_status_warn;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ========================================
      -- A-4.���[�N�e�[�u���o��
      -- ========================================
      insert_row(
        i_rp_qte_lst_data_rec  => l_rp_qte_lst_data_rec  -- ���σf�[�^
       ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ��s�o�͗p�y�[�W�A���R�[�h���J�E���g
      -- ���[��1�y�[�W�ڂ�
      IF (gn_page_cnt = cn_page_cnt1) THEN
        -- ���R�[�h��15���R�[�h�ȏォ
        IF (gn_rec_cnt >= cn_rec_cnt15) THEN
          -- �y�[�W���J�E���g�A�b�v���A���R�[�h����1��ݒ肷��
          gn_page_cnt := gn_page_cnt + 1;
          gn_rec_cnt  := cn_rec_cnt1;
        ELSE
          gn_rec_cnt := gn_rec_cnt + 1;
        END IF;
      ELSE
        -- ���R�[�h��21���R�[�h�ȏォ
        IF (gn_rec_cnt >= cn_rec_cnt21) THEN
          -- �y�[�W���J�E���g�A�b�v���A���R�[�h����1��ݒ肷��
          gn_page_cnt := gn_page_cnt + 1;
          gn_rec_cnt  := cn_rec_cnt1;
        ELSE
          gn_rec_cnt := gn_rec_cnt + 1;
        END IF;
      END IF;
--
      -- INSERT�����������J�E���g�A�b�v
      ln_ins_cnt := ln_ins_cnt + 1;
--
    END LOOP get_quote_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_quote_data_cur;
--
    -- �����Ώۃf�[�^��0���̏ꍇ�AIN�p�����[�^.���σw�b�_�[�h�c��茩�ϔԍ����擾
    IF (gn_target_cnt = 0) THEN
      BEGIN
        SELECT xqh.quote_number   quote_number     -- ���ϔԍ�
        INTO   lt_quote_number
        FROM   xxcso_quote_headers  xqh   -- ���σw�b�_�[�e�[�u��
        WHERE  xqh.quote_header_id = ln_qt_hdr_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_03    --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_param1       --�g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_qt_info      --�g�[�N���l1
                    );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE no_data_expt;
        WHEN OTHERS THEN
          RAISE;
      END;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_07        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_qt_num           --�g�[�N���R�[�h1
                 ,iv_token_value1 => lt_quote_number         --�g�[�N���l1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
    -- ========================================
    -- A-5.��s�o�͏���
    -- ========================================
    -- ���[��1�y�[�W�ڂ�
    IF (gn_page_cnt = cn_page_cnt1) THEN
      -- ���R�[�h��12���R�[�h�ȉ���
      IF (gn_rec_cnt <= cn_rec_cnt12) THEN
        -- 12��背�R�[�h����������������s��o�^����
        ln_rec_num  := cn_rec_cnt12 - gn_rec_cnt;
      -- ���R�[�h��13�`15���R�[�h�̊Ԃ�
      ELSIF (gn_rec_cnt BETWEEN cn_rec_cnt13 AND cn_rec_cnt15) THEN
        -- 34��背�R�[�h����������������s��o�^����
        ln_rec_num  := cn_rec_cnt34 - gn_rec_cnt;
      END IF;
    ELSE
      -- ���R�[�h��19���R�[�h�ȉ���
      IF (gn_rec_cnt <= cn_rec_cnt19) THEN
        -- 19��背�R�[�h����������������s��o�^����
        ln_rec_num  := cn_rec_cnt19 - gn_rec_cnt;
      -- ���R�[�h��20�`21���R�[�h�̊Ԃ�
      ELSIF (gn_rec_cnt BETWEEN cn_rec_cnt20 AND cn_rec_cnt21) THEN
        -- 40��背�R�[�h����������������s��o�^����
        ln_rec_num  := cn_rec_cnt40 - gn_rec_cnt;
      END IF;
    END IF;
--
    -- ��s�o�͏���
    LOOP <<insert_blanks_loop>>
      -- ��s�o�͗p���R�[�h�������o�͂������_��EXIT����
      EXIT WHEN ln_loop_cnt = ln_rec_num;
      --
      insert_blanks(
         i_rp_qte_lst_data_rec => l_rp_qte_lst_data_rec    -- ���σf�[�^
        ,ov_errbuf     => lv_errbuf                        -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode    => lv_retcode                       -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg     => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
      ln_loop_cnt := ln_loop_cnt +1;
    END LOOP insert_blanks_loop;
--

    -- ========================================
    -- A-6.SVF�N��
    -- ========================================
    act_svf(
       ov_errbuf     => lv_errbuf_svf                    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode_svf                   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg_svf                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF  (lv_retcode_svf <> cv_status_error) THEN
      gn_normal_cnt := ln_ins_cnt;
    END IF;
--
    -- ========================================
    -- A-7.���[�N�e�[�u���f�[�^�폜
    -- ========================================
    delete_row(
       ov_errbuf     => lv_errbuf                        -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode                       -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-8.SVF�N��API�G���[�`�F�b�N
    -- ========================================
    IF (lv_retcode_svf = cv_status_error) THEN
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_quote_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_quote_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_quote_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_quote_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,in_qt_hdr_id  IN  NUMBER             --   ���σw�b�_�[ID
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_log_msg         CONSTANT VARCHAR2(100) := '�V�X�e���G���[���������܂����B�V�X�e���Ǘ��҂Ɋm�F���Ă��������B';
    -- �G���[���b�Z�[�W
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';  -- �R���J�����g�w�b�_���b�Z�[�W�o�� �o�͋敪
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       in_qt_hdr_id   => in_qt_hdr_id       -- ���σw�b�_�[ID
      ,ov_errbuf      => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => SUBSTRB(
                      cv_log_msg ||cv_msg_prnthss_l||
                      cv_pkg_name||cv_msg_cont||
                      cv_prg_name||cv_msg_part||
                      lv_errbuf  ||cv_msg_prnthss_r,1,5000
                    )
       );                                                     --�G���[���b�Z�[�W
    END IF;
--
    -- =======================
    -- A-9.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO017A03C;
/
