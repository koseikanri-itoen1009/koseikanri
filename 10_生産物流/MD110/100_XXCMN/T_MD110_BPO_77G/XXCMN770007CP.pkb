CREATE OR REPLACE PACKAGE BODY xxcmn770007cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770007CP(body)
 * Description      : ���Y�������ٕ\(�v���g)
 * MD.050           : �L���x�����[Issue1.0(T_MD050_BPO_770)
 * MD.070           : �L���x�����[Issue1.0(T_MD070_BPO_77G)
 * Version          : 1.17
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(G-1)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(G-1)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(G-2)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/09    1.0   K.Kamiyoshi      �V�K�쐬
 *  2008/05/16    1.1   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂��ꂽ���A�G���[
 *                                       �ƂȂ�_���C���B
 *                                       �S�������A�S���Җ��̍ő咷�������C���B
 *  2008/05/30    1.2   T.Ikehara        �����擾���@�C��
 *  2008/06/03    1.3   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/12    1.4   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜
 *  2008/06/24    1.5   T.Ikehara        ���ʁA���z��0�̏ꍇ�ɏo�͂����悤�ɏC��
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/29    1.7   A.Shiina         T_TE080_BPO_770 �w�E20�Ή�
 *  2008/10/08    1.8   A.Shiina         T_S_524�Ή�
 *  2008/10/08    1.9   A.Shiina         T_S_455�Ή�
 *  2008/10/09    1.10  A.Shiina         T_S_422�Ή�
 *  2008/11/11    1.11  N.Yoshida        I_S_511�Ή��A�ڍs�f�[�^���ؕs��Ή�
 *  2008/11/19    1.12  N.Yoshida        �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/29    1.13  N.Yoshida        �{��#212�Ή�
 *  2008/12/04    1.14  T.Mitaya         �{��#379�Ή�
 *  2009/01/16    1.15  N.Yoshida        �{��#1031�Ή�
 *  2009/06/22    1.16  Marushita        �{��#1541�Ή�
 *  2009/06/29    1.17  Marushita        �{��#1554�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxcmn770007' ;   -- �p�b�P�[�W��
--
  gv_raw_mat_cost_name    CONSTANT VARCHAR2(100) := '����';
  gv_agein_cost_name      CONSTANT VARCHAR2(100) := '�Đ���';
  gv_material_cost_name   CONSTANT VARCHAR2(100) := '���ޔ�';
  gv_pack_cost_name       CONSTANT VARCHAR2(100) := '���';
  gv_out_order_cost_name  CONSTANT VARCHAR2(100) := '�O�����H��';
  gv_safekeep_cost_name   CONSTANT VARCHAR2(100) := '�ۊǔ�';
  gv_other_cost_name      CONSTANT VARCHAR2(100) := '���̑��o��';
  gv_spare1_name          CONSTANT VARCHAR2(100) := '�\���P';
  gv_spare2_name          CONSTANT VARCHAR2(100) := '�\���Q';
  gv_spare3_name          CONSTANT VARCHAR2(100) := '�\���R';
  gv_lookup_code          CONSTANT VARCHAR2(1)   := '2';
  gv_product              CONSTANT VARCHAR2(1)   := '5';
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_lang                 CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_y                    CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_new_acnt_div         CONSTANT VARCHAR2(21)  := 'XXCMN_NEW_ACCOUNT_DIV';
  gc_output_flag          CONSTANT VARCHAR2(30)  := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
--
  gv_expense_item_type    CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE';  -- ��ڋ敪
  gv_cmpntcls_type        CONSTANT VARCHAR2(100) := 'XXCMN_D19';               -- ��������敪
--
  ------------------------------
  -- �S�p����
  ------------------------------
  gc_cat_prod_div         CONSTANT VARCHAR2(8)   := '���i�敪' ;
  gc_cat_item_div         CONSTANT VARCHAR2(8)   := '�i�ڋ敪' ;
  gc_cap_from             CONSTANT VARCHAR2(14)  := '�����N��(FROM)' ;
  gc_cap_to               CONSTANT VARCHAR2(12)  := '�����N��(TO)' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;      -- �A�v���P�[�V�����iXXCMN�j
  gc_param_name           CONSTANT VARCHAR2(10) := 'PARAM_NAME' ;
  gc_param_value          CONSTANT VARCHAR2(11) := 'PARAM_VALUE';
--
  ------------------------------
  -- ���t���ڕҏW�֘A
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '�N' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '��' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '��' ;
  gc_char_y_format        CONSTANT VARCHAR2(20) := 'YYYYMM';
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
  gn_one                 CONSTANT NUMBER      := 1  ;
  gn_thousand            CONSTANT NUMBER      := 1000 ;
--
  ------------------------------
  -- �����敪
  ------------------------------
  gc_cost_ac             CONSTANT VARCHAR2(1) := '0';--���ی���
  gc_cost_st             CONSTANT VARCHAR2(1) := '1';--�W������
--
  ------------------------------
  -- ���b�g�Ǘ��敪
  ------------------------------
  gc_lot_view            CONSTANT NUMBER      := 0;--���b�g�Ǘ��ΏۊO
  gc_lot_ine             CONSTANT NUMBER      := 1;--���b�g�Ǘ��Ώ�
--
  ------------------------------
  -- �J�[�\���֘A
  ------------------------------
  gc_kan                 CONSTANT VARCHAR2(1) := '1' ;
  gc_tou                 CONSTANT VARCHAR2(2) := '-1';
  gc_huku                CONSTANT VARCHAR2(1) := '2' ;
  gc_sizai               CONSTANT NUMBER      := 2   ;
  gc_gun                 CONSTANT VARCHAR2(1) := '3' ;
  gc_sla                 CONSTANT VARCHAR2(1) := '/' ;
  gc_sla_zero_one        CONSTANT VARCHAR2(3) := '/01' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data IS RECORD(
      proc_from            VARCHAR2(6)   -- �����N��FROM
     ,proc_from_date_ch    VARCHAR2(10)  -- �����N��FROM(���t������)
     ,proc_from_date       DATE          -- �����N��FROM(���t) - 1(�挎�̖���)
     ,proc_to              VARCHAR2(6)   -- �����N��TO
     ,proc_to_date_ch      VARCHAR2(10)  -- �����N��TO(���t������)
     ,proc_to_date         DATE          -- �����N��TO(���t) - 1(������1��)
     ,prod_div             VARCHAR2(10)  -- ���i�敪
     ,item_div             VARCHAR2(10)  -- �i�ڋ敪
     ,crowd_type           VARCHAR2(10)  -- �W�v���
     ,crowd_code           VARCHAR2(10)  -- �Q�R�[�h
     ,acnt_crowd_code      VARCHAR2(10)  -- �o���Q�R�[�h
    ) ;
--
    gr_param          rec_param_data ;          -- �p�����[�^��n���p
--
  --�w�b�_�p
  TYPE rec_header     IS RECORD(
      report_id            VARCHAR2(12)     -- ���[ID
     ,exec_date            DATE             -- ���{��
     ,proc_from_char       VARCHAR2(10)                                 --�����N��FROM(YYYY�NMM��)
     ,proc_to_char         VARCHAR2(10)                                 --�����N��TO  (YYYY�NMM��)
     ,user_id              xxpo_per_all_people_f_v.person_id%TYPE       --�S����ID
     ,user_name            per_all_people_f.per_information18%TYPE      --�S����
     ,user_dept            xxcmn_locations_all.location_short_name%TYPE --����
    ) ;
--
  gr_header           rec_header;
--
  -- �d��������ו\�f�[�^�i�[�p���R�[�h�ϐ� --���
  TYPE rec_data_type_dtl  IS RECORD(
       prod_div          xxcmn_lot_each_item_v.prod_div%TYPE   -- ���i�敪
      ,prod_div_name     xxcmn_categories_v.description%TYPE   -- ���i�敪����
      ,item_div          xxcmn_lot_each_item_v.item_div%TYPE   -- �i�ڋ敪
      ,item_div_name     xxcmn_categories_v.description%TYPE   -- �i�ڋ敪����
      ,gun_code          xxcmn_lot_each_item_v.crowd_code%TYPE -- �Q�R�[�h
      ,item_id           ic_tran_pnd.item_id%TYPE              -- �i��ID
      ,item_code         xxcmn_lot_each_item_v.item_code%TYPE  -- �i�ڃR�[�h
      ,item_name         ic_item_mst_b.item_desc1%TYPE         -- �i�ږ���
-- 2008/11/29 v1.13 UPDATE START
      --,item_net          ic_item_mst_b.attribute12%TYPE        -- NET
-- 2008/11/29 v1.13 UPDATE END
      ,trans_qty         NUMBER                                -- �������
      ,kan_qty           NUMBER                                -- �������(�����i)
      ,tou_qty           NUMBER                                -- �������(�����i)
      ,huku_qty          NUMBER                                -- �������(���Y��)
      ,actual_unit_price NUMBER                                -- ���ےP��
      ,kan_jitu          NUMBER                                -- ���ےP���~������� �����i
      ,tou_jitu          NUMBER                                -- ���ےP���~������� �����i
      ,cmpnt_cost        NUMBER                                -- �W������(������)
      ,cmpnt_huku        NUMBER                                -- �W������(������)�~������� ���Y��
      ,cmpnt_kin         NUMBER                                -- �W������(������)�~�������
      ,tou_kin           NUMBER                                -- �������z
      ,uti_kin           NUMBER                                -- �ō����z
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  gr_rec tab_data_type_dtl;
--
  --�L�[���ꔻ�f�p
  TYPE rec_keybreak  IS RECORD(
       prod_div       VARCHAR2(200)  --���i�敪
     , item_div       VARCHAR2(200)  --�i�ڋ敪
     , crowd_high     VARCHAR2(200)  --��Q
     , crowd_mid      VARCHAR2(200)  --���Q
     , crowd_low      VARCHAR2(200)  --���Q
     , crowd_dtl      VARCHAR2(200)  --�ڌQ
    ) ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;  -- �c�ƒP��
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  ------------------------------
  -- ���b�N�A�b�v�p
  ------------------------------
  gv_tax_class              fnd_lookup_values.lookup_code%TYPE ;
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
--
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(G-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
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
    lv_rowid       VARCHAR2(5000);            --ROWID
    lv_date        VARCHAR2(10);   --���t�ݒ�p
    lv_f_date      VARCHAR2(20);
    lv_e_date      VARCHAR2(20);
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- ���[�o�͒l�i�[
    gr_header.report_id                   := 'XXCMN770007T'  ;     -- ���[ID
    gr_header.exec_date                   := SYSDATE        ;      -- ���{��
--
    -- ====================================================
    -- �Ώ۔N��
    -- ====================================================
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      gr_param.proc_from , gc_char_y_format),gc_char_y_format);
--
    --���t�^�ݒ�
    gr_param.proc_from_date_ch :=   SUBSTR(gr_param.proc_from,1,4) || gc_sla
                                 || SUBSTR(gr_param.proc_from,5,2) || gc_sla_zero_one;
    gr_param.proc_from_date :=  FND_DATE.STRING_TO_DATE( gr_param.proc_from_date_ch
                                                              , gc_char_d_format) - 1;
    --���t�ϊ�
    gr_header.proc_from_char :=   SUBSTR(lv_f_date,1,4) || gc_jp_yy
                             || SUBSTR(lv_f_date,5,2) || gc_jp_mm;
    IF (gr_param.proc_from_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              , 'APP-XXCMN-10035'
                                              , gc_param_name
                                              , gc_cap_from
                                              , gc_param_value
                                              , gr_param.proc_from ) ;
      RAISE get_value_expt ;
    END IF;
--
    lv_e_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      gr_param.proc_to , gc_char_y_format),gc_char_y_format);
--
    gr_param.proc_to_date_ch :=   SUBSTR(gr_param.proc_to,1,4) || gc_sla
                               || SUBSTR(gr_param.proc_to,5,2) || gc_sla_zero_one;
    gr_param.proc_to_date   :=  ADD_MONTHS(FND_DATE.STRING_TO_DATE( gr_param.proc_to_date_ch
                                                              , gc_char_d_format), 1);
    -- ���t�ϊ�
    gr_header.proc_to_char   :=   SUBSTR(lv_e_date,1,4) || gc_jp_yy
                                      || SUBSTR(lv_e_date,5,2) || gc_jp_mm;
--
    IF (gr_param.proc_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              , 'APP-XXCMN-10035'
                                              , gc_param_name
                                              , gc_cap_to
                                              , gc_param_value
                                              , gr_param.proc_to ) ;
      RAISE get_value_expt ;
    END IF;
    gr_param.proc_to_date_ch := TO_CHAR(gr_param.proc_to_date,gc_char_d_format);
--
    -- ====================================================
    -- �c�ƒP�ʎ擾
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXPO-00005'    ) ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �S�������E�S���Җ�
    -- ====================================================
    BEGIN
      gr_header.user_id   := FND_GLOBAL.USER_ID;
      gr_header.user_dept := xxcmn_common_pkg.get_user_dept(gr_header.user_id);
      gr_header.user_name := xxcmn_common_pkg.get_user_name(gr_header.user_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL ;
    END;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
  END prc_initialize ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(G-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
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
    cn_prod_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));

--
    -- *** ���[�J���E�ϐ� ***
    lv_date_from       VARCHAR2(10) ;
    lv_date_to         VARCHAR2(10) ;
    lv_syukei_select   VARCHAR2(32000) ;
    lv_syukei_from     VARCHAR2(32000) ;
    lv_syukei_where    VARCHAR2(32000) ;
    lv_syukei_group_by VARCHAR2(32000) ;
    lv_syukei          VARCHAR2(32000) ;
    lv_select          VARCHAR2(32000) ;
    lv_from            VARCHAR2(32000) ;
    lv_where           VARCHAR2(32000) ;
    lv_group_by        VARCHAR2(32000) ;
    lv_order_by        VARCHAR2(32000) ;
    lv_sql             VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
    CURSOR get_data_cur01 IS
      SELECT /*+ leading (gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) use_nl(gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) */
             mcb1.segment1                     prod_div 
           , mct1.description                  prod_div_name
           , mcb2.segment1                     item_div 
           , mct2.description                  item_div_name
           , mcb3.segment1                     gun_code
           , gmd1.item_id                      item_id 
           , iimb2.item_no                     item_code 
           , ximb2.item_short_name             item_name 
-- 2008/11/29 v1.13 UPDATE START
           --, NVL(iimb2.attribute12,1)          item_net
-- 2008/11/29 v1.13 UPDATE END
           , SUM(NVL(itp.trans_qty , 0) * TO_NUMBER(xrpm.rcv_pay_div))       trans_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0))                                            kan_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) tou_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) huku_qty 
-- 2008/11/19 v1.12 UPDATE START
           , SUM(NVL(DECODE(iimb.attribute15
--                           ,gc_cost_st,xcup.stnd_unit_price
                           ,gc_cost_st,xcup2.stnd_unit_price
                           ,gc_cost_ac,DECODE(iimb.lot_ctl
                                             ,gc_lot_ine,xlc.unit_ploce
--                                             ,gc_lot_view,xcup.stnd_unit_price)),0)) actual_unit_price
                                             ,gc_lot_view,xcup2.stnd_unit_price)),0)) actual_unit_price
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                                 * DECODE(iimb.attribute15
--                                                         ,gc_cost_st,xcup.stnd_unit_price
                                                         ,gc_cost_st,xcup2.stnd_unit_price
                                                         ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                           ,gc_lot_ine,xlc.unit_ploce
--                                                                           ,gc_lot_view,xcup.stnd_unit_price)))),0)
                                                                           ,gc_lot_view,xcup2.stnd_unit_price)))),0)
                )   kan_jitu 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                                 * DECODE(iimb.attribute15
--                                                         ,gc_cost_st,xcup.stnd_unit_price
                                                         ,gc_cost_st,xcup2.stnd_unit_price
                                                         ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                           ,gc_lot_ine,xlc.unit_ploce
--                                                                           ,gc_lot_view,xcup.stnd_unit_price)))),0)
                                                                           ,gc_lot_view,xcup2.stnd_unit_price)))),0)
                )   tou_jitu 
-- 2008/11/19 v1.12 UPDATE END
           --, SUM(NVL(xcup.stnd_unit_price , 0))                          cmpnt_cost 
-- 2008/11/29 v1.13 UPDATE START
           --, NVL(xcup.stnd_unit_price , 0)     cmpnt_cost
           , NVL(xcup.stnd_unit_price_gen , 0)     cmpnt_cost
-- 2008/11/29 v1.13 UPDATE END
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
-- 2008/11/29 v1.13 UPDATE START
-- 2008/11/19 v1.12 UPDATE START
                             -- * xcup2.stnd_unit_price)), 0)) cmpnt_huku 
                             * xcup2.stnd_unit_price_gen)), 0)) cmpnt_huku 
-- 2008/11/19 v1.12 UPDATE END
-- 2008/11/29 v1.13 UPDATE END
-- 2008/11/19 v1.12 UPDATE START
           --, SUM(NVL(xcup.stnd_unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)), 0)
-- 2008/11/29 v1.13 UPDATE START
           --, SUM(NVL(xcup.stnd_unit_price , 0) * NVL(DECODE(xrpm.line_type
           , SUM(NVL(xcup.stnd_unit_price_gen , 0) * NVL(DECODE(xrpm.line_type
-- 2008/11/29 v1.13 UPDATE END
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)
-- 2008/11/19 v1.12 UPDATE END
             ) cmpnt_kin 
           , SUM(NVL(CASE  -- �����i�Ŏ��ވȊO
                     WHEN xrpm.line_type =   gc_tou  
-- 2008/12/04 v1.14 UPDATE START
--                     AND  mcb2.segment1 <>   gc_sizai  
                     AND  mcb4.segment1 <>   gc_sizai  
-- 2008/12/04 v1.14 UPDATE END
-- 2009/06/29 ADD START
                     AND  NVL(xrpm.hit_in_div,'N') <> gc_y 
-- 2009/06/29 ADD END
                     THEN ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                        * DECODE(iimb.attribute15
-- 2008/11/19 v1.12 UPDATE START
--                                                ,gc_cost_st,xcup.stnd_unit_price
                                                ,gc_cost_st,xcup2.stnd_unit_price
                                                ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                  ,gc_lot_ine,xlc.unit_ploce
--                                                                  ,gc_lot_view,xcup.stnd_unit_price)))
                                                                  ,gc_lot_view,xcup2.stnd_unit_price)))
                     END  , 0))                                              tou_kin 
           , SUM(NVL(DECODE(xrpm.hit_in_div
                           ,gc_y, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                               * DECODE(iimb.attribute15
--                                                       ,gc_cost_st,xcup.stnd_unit_price
                                                       ,gc_cost_st,xcup2.stnd_unit_price
                                                       ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                         ,gc_lot_ine,xlc.unit_ploce
--                                                                         ,gc_lot_view,xcup.stnd_unit_price))),0),0)
                                                                         ,gc_lot_view,xcup2.stnd_unit_price))),0),0)
-- 2008/11/19 v1.12 UPDATE END
                ) uti_kin 
      FROM
            ic_tran_pnd              itp      --�݌Ƀg����
           ,gmi_item_categories      gic1
           ,mtl_categories_b         mcb1
           ,mtl_categories_tl        mct1
           ,gmi_item_categories      gic2
           ,mtl_categories_b         mcb2
           ,mtl_categories_tl        mct2
           ,gmi_item_categories      gic3
           ,mtl_categories_b         mcb3
           ,ic_item_mst_b            iimb
           ,xxcmn_item_mst_b         ximb
           ,ic_item_mst_b            iimb2
           ,xxcmn_item_mst_b         ximb2
           ,xxcmn_lot_cost           xlc
           ,xxcmn_stnd_unit_price_v  xcup     --�W���������View
-- 2008/11/19 v1.12 ADD START
           ,xxcmn_stnd_unit_price_v  xcup2    --�W���������View
-- 2008/11/19 v1.12 ADD END
           ,gme_material_details     gmd1     -- 
-- 2009/06/29 ADD START
           ,gme_material_details     gmd4     -- 
-- 2009/06/29 ADD END
           ,gme_batch_header         gbh1     -- 
           ,gmd_routings_b           grb1     -- 
           ,xxcmn_rcv_pay_mst        xrpm
-- 2008/12/04 v1.14 ADD START
           ,gmi_item_categories      gic4
           ,mtl_categories_b         mcb4
-- 2008/12/04 v1.14 ADD END
      WHERE  itp.doc_type          = 'PROD'
      AND    itp.completed_ind     = 1
      AND    gmd1.attribute11     >= gr_param.proc_from_date_ch
      AND    gmd1.attribute11     <  gr_param.proc_to_date_ch
      AND    gic1.item_id          = gmd1.item_id
      AND    gic1.category_set_id  = cn_prod_class_id
      AND    mcb1.category_id      = gic1.category_id
      AND    mcb1.segment1         = gr_param.prod_div  --@@���i�敪
      AND    mct1.category_id      = mcb1.category_id
      AND    mct1.language         = 'JA'
      AND    gic2.item_id          = gmd1.item_id
      AND    gic2.category_set_id  = cn_item_class_id
      AND    mcb2.category_id      = gic2.category_id
      AND    mcb2.segment1         = gr_param.item_div  --@@�i�ڋ敪
      AND    mct2.category_id      = mcb2.category_id
      AND    mct2.language         = 'JA'
      AND    gic3.item_id          = gmd1.item_id
      AND    gic3.category_set_id  = cn_crowd_code_id
      AND    mcb3.category_id      = gic3.category_id
      AND    iimb.item_id          = itp.item_id
      AND    ximb.item_id          = iimb.item_id
      AND    itp.trans_date        BETWEEN ximb.start_date_active AND ximb.end_date_active
      AND    xlc.item_id(+)        = itp.item_id
      AND    xlc.lot_id(+)         = itp.lot_id
-- 2008/11/19 v1.12 UPDATE START
      AND    xcup.item_id(+)       = gmd1.item_id
      AND    itp.trans_date        BETWEEN NVL(xcup.start_date_active, FND_DATE.STRING_TO_DATE('1900/01/01 00:00:00', 'YYYY/MM/DD HH24:MI:SS'))
                                   AND NVL(xcup.end_date_active, FND_DATE.STRING_TO_DATE('9999/12/31 23:59:59', 'YYYY/MM/DD HH24:MI:SS'))
      AND    xcup2.item_id(+)      = itp.item_id
      AND    itp.trans_date        BETWEEN xcup2.start_date_active(+) AND xcup2.end_date_active(+) 
-- 2008/11/19 v1.12 UPDATE END
      AND    itp.doc_id            = gmd1.batch_id
-- 2009/01/16 v1.15 N.Yoshida mod start
--      AND    itp.doc_line          = gmd1.line_no
-- 2009/01/16 v1.15 N.Yoshida mod end
      AND    gbh1.batch_id         = gmd1.batch_id
      AND    grb1.routing_id       = gbh1.routing_id
      AND    xrpm.routing_class    = grb1.routing_class
      AND    gmd1.item_id          = iimb2.item_id
      AND    iimb2.item_id         = ximb2.item_id
      AND    itp.doc_type           = xrpm.doc_type
      AND    itp.line_type          = xrpm.line_type
-- 2008/12/04 v1.14 ADD START
      AND    itp.item_id = gic4.item_id
      AND    gic4.category_id = mcb4.category_id
      AND    gic4.category_set_id = cn_item_class_id
-- 2008/12/04 v1.14 ADD END
      --AND    gmd1.line_type         = xrpm.line_type
      AND    gmd1.line_type         = gc_kan
-- 2009/06/29 MOD START
--      AND    ( ( ( gmd1.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
--             OR ( xrpm.hit_in_div        = gmd1.attribute5 ) )
      AND    itp.doc_id            = gmd4.batch_id
      AND    itp.item_id           = gmd4.item_id
      AND    itp.line_type         = gmd4.line_type
      AND    itp.line_id           = gmd4.material_detail_id
      AND    ( ( ( gmd4.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
             OR ( xrpm.hit_in_div        = gmd4.attribute5 ) )
-- 2009/06/29 MOD END
      AND    xrpm.break_col_07       IS NOT NULL
      AND    ((xrpm.routing_class    <> '70')  --PTN A
             OR (xrpm.routing_class     = '70' --PTN B
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd2
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd2.batch_id   = gmd1.batch_id
                              AND    gmd2.line_no    = gmd1.line_no
                              AND    gmd2.line_type  = -1
                              AND    gic.item_id     = gmd2.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_origin))
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd3
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd3.batch_id   = gmd1.batch_id
                              AND    gmd3.line_no    = gmd1.line_no
                              AND    gmd3.line_type  = 1
                              AND    gic.item_id     = gmd3.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_ahead))
              ))
      GROUP BY 
               mcb1.segment1
             , mct1.description
             , mcb2.segment1
             , mct2.description
             , mcb3.segment1
             , gmd1.item_id
             , iimb2.item_no
             , ximb2.item_short_name
-- 2008/11/29 v1.13 UPDATE START
             --, iimb2.attribute12
-- 2008/11/29 v1.13 UPDATE END
             , xcup.stnd_unit_price_gen
      ORDER BY 
               mcb3.segment1
              ,iimb2.item_no
      ;
--
    CURSOR get_data_cur02 IS
      SELECT /*+ leading (gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) use_nl(gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) */
             mcb1.segment1                     prod_div 
           , mct1.description                  prod_div_name
           , mcb2.segment1                     item_div 
           , mct2.description                  item_div_name
           , mcb3.segment1                     gun_code
           , gmd1.item_id                      item_id 
           , iimb2.item_no                     item_code 
           , ximb2.item_short_name             item_name 
-- 2008/11/29 v1.13 UPDATE START
           --, NVL(iimb2.attribute12,1)          item_net
-- 2008/11/29 v1.13 UPDATE END
           , SUM(NVL(itp.trans_qty , 0) * TO_NUMBER(xrpm.rcv_pay_div))       trans_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0))                                            kan_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) tou_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) huku_qty 
           , SUM(NVL(DECODE(iimb.attribute15
                           ,gc_cost_st
                           ,(SELECT NVL(SUM(xpl.unit_price),0)
                             FROM   xxpo_price_headers    xph
                                   ,xxpo_price_lines      xpl
                                   ,xxcmn_lookup_values_v xlvv1
                                   ,xxcmn_lookup_values_v xlvv2
                             WHERE  xph.price_header_id   = xpl.price_header_id
                             AND    xpl.expense_item_type = xlvv1.attribute1
                             AND    xlvv1.attribute2      = xlvv2.lookup_code
                             AND    xph.price_type        = gv_lookup_code
                             AND    xph.item_code         = iimb.item_no
                             -- 2009/06/22 ADD START
                             AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                             -- 2009/06/22 ADD END
                             AND    xlvv1.lookup_type     = gv_expense_item_type
                             AND    xlvv2.lookup_type     = gv_cmpntcls_type
                             AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                              ,gv_agein_cost_name
                                                              ,gv_material_cost_name
                                                              ,gv_pack_cost_name
                                                              ,gv_out_order_cost_name
                                                              ,gv_safekeep_cost_name
                                                              ,gv_other_cost_name
                                                              ,gv_spare1_name
                                                              ,gv_spare2_name
                                                              ,gv_spare3_name))
                           ,gc_cost_ac,DECODE(iimb.lot_ctl
                                             ,gc_lot_ine,xlc.unit_ploce
                                             ,gc_lot_view
                                         ,(SELECT NVL(SUM(xpl.unit_price),0)
                                           FROM   xxpo_price_headers    xph
                                                 ,xxpo_price_lines      xpl
                                                 ,xxcmn_lookup_values_v xlvv1
                                                 ,xxcmn_lookup_values_v xlvv2
                                           WHERE  xph.price_header_id   = xpl.price_header_id
                                           AND    xpl.expense_item_type = xlvv1.attribute1
                                           AND    xlvv1.attribute2      = xlvv2.lookup_code
                                           AND    xph.price_type        = gv_lookup_code
                                           AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                           AND    xlvv1.lookup_type     = gv_expense_item_type
                                           AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                           AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                            ,gv_spare1_name
                                                                            ,gv_spare2_name
                                                                            ,gv_spare3_name))
                                             )),0)) actual_unit_price 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * DECODE(iimb.attribute15
                                     ,gc_cost_st
                                     ,(SELECT NVL(SUM(xpl.unit_price),0)
                                       FROM   xxpo_price_headers    xph
                                             ,xxpo_price_lines      xpl
                                             ,xxcmn_lookup_values_v xlvv1
                                             ,xxcmn_lookup_values_v xlvv2
                                       WHERE  xph.price_header_id   = xpl.price_header_id
                                       AND    xpl.expense_item_type = xlvv1.attribute1
                                       AND    xlvv1.attribute2      = xlvv2.lookup_code
                                       AND    xph.price_type        = gv_lookup_code
                                       AND    xph.item_code         = iimb.item_no
                                       -- 2009/06/22 ADD START
                                       AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                       -- 2009/06/22 ADD END
                                       AND    xlvv1.lookup_type     = gv_expense_item_type
                                       AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                       AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                        ,gv_agein_cost_name
                                                                        ,gv_material_cost_name
                                                                        ,gv_pack_cost_name
                                                                        ,gv_out_order_cost_name
                                                                        ,gv_safekeep_cost_name
                                                                        ,gv_other_cost_name
                                                                        ,gv_spare1_name
                                                                        ,gv_spare2_name
                                                                        ,gv_spare3_name))
                                     ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                       ,gc_lot_ine,xlc.unit_ploce
                                                       ,gc_lot_view
                                          ,(SELECT NVL(SUM(xpl.unit_price),0)
                                            FROM   xxpo_price_headers    xph
                                                  ,xxpo_price_lines      xpl
                                                  ,xxcmn_lookup_values_v xlvv1
                                                  ,xxcmn_lookup_values_v xlvv2
                                            WHERE  xph.price_header_id   = xpl.price_header_id
                                            AND    xpl.expense_item_type = xlvv1.attribute1
                                            AND    xlvv1.attribute2      = xlvv2.lookup_code
                                            AND    xph.price_type        = gv_lookup_code
                                            AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                            AND    xlvv1.lookup_type     = gv_expense_item_type
                                            AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                            AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                             ,gv_agein_cost_name
                                                                             ,gv_material_cost_name
                                                                             ,gv_pack_cost_name
                                                                             ,gv_out_order_cost_name
                                                                             ,gv_safekeep_cost_name
                                                                             ,gv_other_cost_name
                                                                             ,gv_spare1_name
                                                                             ,gv_spare2_name
                                                                             ,gv_spare3_name))
                                                       )))),0))   kan_jitu 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * DECODE(iimb.attribute15
                                     ,gc_cost_st
                                     ,(SELECT NVL(SUM(xpl.unit_price),0)
                                       FROM   xxpo_price_headers    xph
                                             ,xxpo_price_lines      xpl
                                             ,xxcmn_lookup_values_v xlvv1
                                             ,xxcmn_lookup_values_v xlvv2
                                       WHERE  xph.price_header_id   = xpl.price_header_id
                                       AND    xpl.expense_item_type = xlvv1.attribute1
                                       AND    xlvv1.attribute2      = xlvv2.lookup_code
                                       AND    xph.price_type        = gv_lookup_code
                                       AND    xph.item_code         = iimb.item_no
                                       -- 2009/06/22 ADD START
                                       AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                       -- 2009/06/22 ADD END
                                       AND    xlvv1.lookup_type     = gv_expense_item_type
                                       AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                       AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                        ,gv_agein_cost_name
                                                                        ,gv_material_cost_name
                                                                        ,gv_pack_cost_name
                                                                        ,gv_out_order_cost_name
                                                                        ,gv_safekeep_cost_name
                                                                        ,gv_other_cost_name
                                                                        ,gv_spare1_name
                                                                        ,gv_spare2_name
                                                                        ,gv_spare3_name))
                                     ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                       ,gc_lot_ine,xlc.unit_ploce
                                                       ,gc_lot_view
                                          ,(SELECT NVL(SUM(xpl.unit_price),0)
                                            FROM   xxpo_price_headers    xph
                                                  ,xxpo_price_lines      xpl
                                                  ,xxcmn_lookup_values_v xlvv1
                                                  ,xxcmn_lookup_values_v xlvv2
                                            WHERE  xph.price_header_id   = xpl.price_header_id
                                            AND    xpl.expense_item_type = xlvv1.attribute1
                                            AND    xlvv1.attribute2      = xlvv2.lookup_code
                                            AND    xph.price_type        = gv_lookup_code
                                            AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                            AND    xlvv1.lookup_type     = gv_expense_item_type
                                            AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                            AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                              ,gv_spare1_name
                                                                              ,gv_spare2_name
                                                                              ,gv_spare3_name))
                                                       )))),0))   tou_jitu 
-- 2009/01/16 v1.15 N.Yoshida mod start
--           , SUM(NVL((SELECT NVL(SUM(xpl.unit_price),0)
           -- �W��������������擾����ׂ�MAX�֐����g�p
           , MAX(NVL((SELECT NVL(SUM(xpl.unit_price),0)
-- 2009/01/16 v1.15 N.Yoshida mod end
                      FROM   xxpo_price_headers    xph
                            ,xxpo_price_lines      xpl
                            ,xxcmn_lookup_values_v xlvv1
                            ,xxcmn_lookup_values_v xlvv2
                      WHERE  xph.price_header_id   = xpl.price_header_id
                      AND    xpl.expense_item_type = xlvv1.attribute1
                      AND    xlvv1.attribute2      = xlvv2.lookup_code
                      AND    xph.price_type        = gv_lookup_code
-- 2009/01/16 v1.15 N.Yoshida mod start
--                      AND    xph.item_code         = iimb.item_no
                      AND    xph.item_code         = iimb2.item_no
-- 2009/01/16 v1.15 N.Yoshida mod end
                      -- 2009/06/22 ADD START
                      AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                      -- 2009/06/22 ADD END
                      AND    xlvv1.lookup_type     = gv_expense_item_type
                      AND    xlvv2.lookup_type     = gv_cmpntcls_type
                      AND    xlvv2.meaning         = gv_raw_mat_cost_name)
             , 0))                          cmpnt_cost 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * (SELECT NVL(SUM(xpl.unit_price),0)
                                FROM   xxpo_price_headers    xph
                                      ,xxpo_price_lines      xpl
                                      ,xxcmn_lookup_values_v xlvv1
                                      ,xxcmn_lookup_values_v xlvv2
                                WHERE  xph.price_header_id   = xpl.price_header_id
                                AND    xpl.expense_item_type = xlvv1.attribute1
                                AND    xlvv1.attribute2      = xlvv2.lookup_code
                                AND    xph.price_type        = gv_lookup_code
                                AND    xph.item_code         = iimb.item_no
                                -- 2009/06/22 ADD START
                                AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                -- 2009/06/22 ADD END
                                AND    xlvv1.lookup_type     = gv_expense_item_type
                                AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                AND    xlvv2.meaning         = gv_raw_mat_cost_name)
                           )), 0)) cmpnt_huku 
           , SUM(ROUND(NVL((SELECT NVL(SUM(xpl.unit_price),0)
                      FROM   xxpo_price_headers    xph
                            ,xxpo_price_lines      xpl
                            ,xxcmn_lookup_values_v xlvv1
                            ,xxcmn_lookup_values_v xlvv2
                      WHERE  xph.price_header_id   = xpl.price_header_id
                      AND    xpl.expense_item_type = xlvv1.attribute1
                      AND    xlvv1.attribute2      = xlvv2.lookup_code
                      AND    xph.price_type        = gv_lookup_code
-- 2009/01/16 v1.15 N.Yoshida mod start
--                      AND    xph.item_code         = iimb.item_no
                      AND    xph.item_code         = iimb2.item_no
-- 2009/01/16 v1.15 N.Yoshida mod end
                      -- 2009/06/22 ADD START
                      AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                      -- 2009/06/22 ADD END
                      AND    xlvv1.lookup_type     = gv_expense_item_type
                      AND    xlvv2.lookup_type     = gv_cmpntcls_type
                      AND    xlvv2.meaning         = gv_raw_mat_cost_name),0)
             * NVL(DECODE(xrpm.line_type
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0))) cmpnt_kin 
           , SUM(NVL(CASE  -- �����i�Ŏ��ވȊO
                     WHEN xrpm.line_type =   gc_tou  
-- 2009/01/16 v1.15 N.Yoshida mod start
--                     AND  mcb2.segment1 <>   gc_sizai  
                     AND  mcb4.segment1 <>   gc_sizai  
-- 2009/01/16 v1.15 N.Yoshida mod end
-- 2009/06/29 ADD START
                     AND  NVL(xrpm.hit_in_div,'N') <> gc_y 
-- 2009/06/29 ADD END
                     THEN ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                       * DECODE(iimb.attribute15
                               ,gc_cost_st
                               ,(SELECT NVL(SUM(xpl.unit_price),0)
                                 FROM   xxpo_price_headers    xph
                                       ,xxpo_price_lines      xpl
                                       ,xxcmn_lookup_values_v xlvv1
                                       ,xxcmn_lookup_values_v xlvv2
                                 WHERE  xph.price_header_id   = xpl.price_header_id
                                 AND    xpl.expense_item_type = xlvv1.attribute1
                                 AND    xlvv1.attribute2      = xlvv2.lookup_code
                                 AND    xph.price_type        = gv_lookup_code
                                 AND    xph.item_code         = iimb.item_no
                                 -- 2009/06/22 ADD START
                                 AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                 -- 2009/06/22 ADD END
                                 AND    xlvv1.lookup_type     = gv_expense_item_type
                                 AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                 AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                  ,gv_agein_cost_name
                                                                  ,gv_material_cost_name
                                                                  ,gv_pack_cost_name
                                                                  ,gv_out_order_cost_name
                                                                  ,gv_safekeep_cost_name
                                                                  ,gv_other_cost_name
                                                                  ,gv_spare1_name
                                                                  ,gv_spare2_name
                                                                  ,gv_spare3_name))
                               ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                 ,gc_lot_ine,xlc.unit_ploce
                                                 ,gc_lot_view
                                         ,(SELECT NVL(SUM(xpl.unit_price),0)
                                           FROM   xxpo_price_headers    xph
                                                 ,xxpo_price_lines      xpl
                                                 ,xxcmn_lookup_values_v xlvv1
                                                 ,xxcmn_lookup_values_v xlvv2
                                           WHERE  xph.price_header_id   = xpl.price_header_id
                                           AND    xpl.expense_item_type = xlvv1.attribute1
                                           AND    xlvv1.attribute2      = xlvv2.lookup_code
                                           AND    xph.price_type        = gv_lookup_code
                                           AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                           AND    xlvv1.lookup_type     = gv_expense_item_type
                                           AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                           AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                            ,gv_spare1_name
                                                                            ,gv_spare2_name
                                                                            ,gv_spare3_name))
                                                 )))
                     END  , 0))                                              tou_kin 
           , SUM(NVL(DECODE(xrpm.hit_in_div
                           ,gc_y, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * DECODE(iimb.attribute15
                                     ,gc_cost_st
                                     ,(SELECT NVL(SUM(xpl.unit_price),0)
                                       FROM   xxpo_price_headers    xph
                                             ,xxpo_price_lines      xpl
                                             ,xxcmn_lookup_values_v xlvv1
                                             ,xxcmn_lookup_values_v xlvv2
                                       WHERE  xph.price_header_id   = xpl.price_header_id
                                       AND    xpl.expense_item_type = xlvv1.attribute1
                                       AND    xlvv1.attribute2      = xlvv2.lookup_code
                                       AND    xph.price_type        = gv_lookup_code
                                       AND    xph.item_code         = iimb.item_no
                                       -- 2009/06/22 ADD START
                                       AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                       -- 2009/06/22 ADD END
                                       AND    xlvv1.lookup_type     = gv_expense_item_type
                                       AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                       AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                        ,gv_agein_cost_name
                                                                        ,gv_material_cost_name
                                                                        ,gv_pack_cost_name
                                                                        ,gv_out_order_cost_name
                                                                        ,gv_safekeep_cost_name
                                                                        ,gv_other_cost_name
                                                                        ,gv_spare1_name
                                                                        ,gv_spare2_name
                                                                        ,gv_spare3_name))
                                     ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                       ,gc_lot_ine,xlc.unit_ploce
                                                       ,gc_lot_view
                                         ,(SELECT NVL(SUM(xpl.unit_price),0)
                                           FROM   xxpo_price_headers    xph
                                                 ,xxpo_price_lines      xpl
                                                 ,xxcmn_lookup_values_v xlvv1
                                                 ,xxcmn_lookup_values_v xlvv2
                                           WHERE  xph.price_header_id   = xpl.price_header_id
                                           AND    xpl.expense_item_type = xlvv1.attribute1
                                           AND    xlvv1.attribute2      = xlvv2.lookup_code
                                           AND    xph.price_type        = gv_lookup_code
                                           AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                           AND    xlvv1.lookup_type     = gv_expense_item_type
                                           AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                           AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                            ,gv_spare1_name
                                                                            ,gv_spare2_name
                                                                            ,gv_spare3_name))
                                                       ))),0),0)
                ) uti_kin 
      FROM
            ic_tran_pnd              itp      --�݌Ƀg����
           ,gmi_item_categories      gic1
           ,mtl_categories_b         mcb1
           ,mtl_categories_tl        mct1
           ,gmi_item_categories      gic2
           ,mtl_categories_b         mcb2
           ,mtl_categories_tl        mct2
           ,gmi_item_categories      gic3
           ,mtl_categories_b         mcb3
-- 2009/01/16 v1.15 N.Yoshida mod start
           ,gmi_item_categories      gic4
           ,mtl_categories_b         mcb4
-- 2009/01/16 v1.15 N.Yoshida mod end
           ,ic_item_mst_b            iimb
           ,xxcmn_item_mst_b         ximb
           ,ic_item_mst_b            iimb2
           ,xxcmn_item_mst_b         ximb2
           ,xxcmn_lot_cost           xlc
           ,gme_material_details     gmd1     -- 
-- 2009/06/29 ADD START
           ,gme_material_details     gmd4     -- 
-- 2009/06/29 ADD END
           ,gme_batch_header         gbh1     -- 
           ,gmd_routings_b           grb1     -- 
           ,xxcmn_rcv_pay_mst xrpm
      WHERE  itp.doc_type          = 'PROD'
      AND    itp.completed_ind     = 1
      AND    gmd1.attribute11     >= gr_param.proc_from_date_ch
      AND    gmd1.attribute11     <  gr_param.proc_to_date_ch
      AND    gic1.item_id          = gmd1.item_id
      AND    gic1.category_set_id  = cn_prod_class_id
      AND    mcb1.category_id      = gic1.category_id
      AND    mcb1.segment1         = gr_param.prod_div  --@@���i�敪
      AND    mct1.category_id      = mcb1.category_id
      AND    mct1.language         = 'JA'
      AND    gic2.item_id          = gmd1.item_id
      AND    gic2.category_set_id  = cn_item_class_id
      AND    mcb2.category_id      = gic2.category_id
      AND    mcb2.segment1         = gr_param.item_div  --@@�i�ڋ敪
      AND    mct2.category_id      = mcb2.category_id
      AND    mct2.language         = 'JA'
      AND    gic3.item_id          = gmd1.item_id
      AND    gic3.category_set_id  = cn_crowd_code_id
      AND    mcb3.category_id      = gic3.category_id
-- 2009/01/16 v1.15 N.Yoshida mod start
      AND    gic4.item_id          = itp.item_id
      AND    gic4.category_set_id  = cn_item_class_id
      AND    mcb4.category_id      = gic4.category_id
-- 2009/01/16 v1.15 N.Yoshida mod end
      AND    iimb.item_id          = itp.item_id
      AND    ximb.item_id          = iimb.item_id
      AND    itp.trans_date        BETWEEN ximb.start_date_active AND ximb.end_date_active
      AND    xlc.item_id(+)        = itp.item_id
      AND    xlc.lot_id(+)         = itp.lot_id
      AND    itp.doc_id            = gmd1.batch_id
-- 2009/01/16 v1.15 N.Yoshida mod start
--      AND    itp.doc_line          = gmd1.line_no
-- 2009/01/16 v1.15 N.Yoshida mod end
      AND    gbh1.batch_id         = gmd1.batch_id
      AND    grb1.routing_id       = gbh1.routing_id
      AND    xrpm.routing_class    = grb1.routing_class
      AND    itp.doc_type           = xrpm.doc_type
      AND    itp.line_type          = xrpm.line_type
      --AND    gmd1.line_type         = xrpm.line_type
      AND    gmd1.item_id          = iimb2.item_id
      AND    iimb2.item_id         = ximb2.item_id
      AND    gmd1.line_type        = gc_kan
-- 2009/06/29 MOD START
--      AND    ( ( ( gmd1.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
--             OR ( xrpm.hit_in_div        = gmd1.attribute5 ) )
      AND    itp.doc_id            = gmd4.batch_id
      AND    itp.item_id           = gmd4.item_id
      AND    itp.line_type         = gmd4.line_type
      AND    itp.line_id           = gmd4.material_detail_id
      AND    ( ( ( gmd4.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
             OR ( xrpm.hit_in_div        = gmd4.attribute5 ) )
-- 2009/06/29 MOD END
      AND    xrpm.break_col_07       IS NOT NULL
      AND    ((xrpm.routing_class    <> '70')  --PTN A
             OR (xrpm.routing_class     = '70' --PTN B
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd2
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd2.batch_id   = gmd1.batch_id
                              AND    gmd2.line_no    = gmd1.line_no
                              AND    gmd2.line_type  = -1
                              AND    gic.item_id     = gmd2.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_origin))
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd3
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd3.batch_id   = gmd1.batch_id
                              AND    gmd3.line_no    = gmd1.line_no
                              AND    gmd3.line_type  = 1
                              AND    gic.item_id     = gmd3.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_ahead))
              ))
      GROUP BY 
               mcb1.segment1
             , mct1.description
             , mcb2.segment1
             , mct2.description
             , mcb3.segment1
             , gmd1.item_id
             , iimb2.item_no
             , ximb2.item_short_name
-- 2008/11/29 v1.13 UPDATE START
             --, iimb2.attribute12
-- 2008/11/29 v1.13 UPDATE END
      ORDER BY 
               mcb3.segment1
              ,iimb2.item_no
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

    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
--
   IF (gr_param.item_div = gv_product) THEN
     OPEN  get_data_cur01;
     FETCH get_data_cur01 BULK COLLECT INTO ot_data_rec;
     CLOSE get_data_cur01;
   ELSE
     OPEN  get_data_cur02;
     FETCH get_data_cur02 BULK COLLECT INTO ot_data_rec;
     CLOSE get_data_cur02;
   END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(G-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break                CONSTANT VARCHAR2(100) := '**' ;
--
    lc_depth_crowd_dtl      CONSTANT NUMBER :=  3;  -- �ڌQ
    lc_depth_crowd_low      CONSTANT NUMBER :=  5;  -- ���Q
    lc_depth_crowd_mid      CONSTANT NUMBER :=  7;  -- ���Q
    lc_depth_crowd_high     CONSTANT NUMBER :=  9;  -- ��Q
    lc_depth_item_div       CONSTANT NUMBER := 13;  -- �i�ڋ敪
    lc_depth_prod_div       CONSTANT NUMBER := 15;  -- ���i�敪
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lb_isfirst              BOOLEAN       DEFAULT TRUE ;
    ln_group_depth          NUMBER;        -- ���s�[�x(�J�n�^�O�o�͗p
    lr_now_key              rec_keybreak;
    lr_pre_key              rec_keybreak;
--
    -- ���z�v�Z�p
    ln_std_cost             NUMBER DEFAULT 0;         -- �W������(������)
    ln_dekikin              NUMBER DEFAULT 0;         -- �o�������z
    ln_dekitan              NUMBER DEFAULT 0;         -- �o�����P��
    ln_sai_tan              NUMBER DEFAULT 0;         -- �P������
    ln_sai_kin              NUMBER DEFAULT 0;         -- ��������
    --�����v�p
    ln_sum_qty              NUMBER DEFAULT 0;         -- �o����
    ln_sum_std_cost         NUMBER DEFAULT 0;         -- �W������
    ln_sum_std_kin          NUMBER DEFAULT 0;         -- �W�����z
    ln_sum_tou              NUMBER DEFAULT 0;         -- �������z
    ln_sum_uti              NUMBER DEFAULT 0;         -- �ō����z
    ln_sum_huku             NUMBER DEFAULT 0;         -- ���Y�����z
    ln_sum_dekikin          NUMBER DEFAULT 0;         -- �o�������z
    ln_sum_dekitan          NUMBER DEFAULT 0;         -- �o�����P��
    ln_sum_sai_tan          NUMBER DEFAULT 0;         -- �P������
    ln_sum_sai_kin          NUMBER DEFAULT 0;         -- ��������
--
    ln_loop_index           NUMBER DEFAULT 0;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
--
    ---------------------
    -- XML�^�O�}������
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR       --   �^�O�^�C�v  T:�^�O
                                                  -- D:�f�[�^
                                                  -- N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                  -- Y:�f�[�^(NULL,0�̏ꍇ�^�O�������Ȃ�)
                                                  -- Z:�f�[�^(NULL�̏ꍇ0�\��)
       ,iv_name              IN        VARCHAR2                --   �^�O��
       ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   �^�O�f�[�^(�ȗ���
       ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   �������i�o�C�g�j(�ȗ���
       ,iv_index             IN        NUMBER    DEFAULT NULL  --   �C���f�b�N�X(�ȗ���
      )
    IS
      -- *** ���[�J���ϐ� ***
      ln_xml_idx  NUMBER;
      ln_work     NUMBER;
      lv_work     VARCHAR2(32000);
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULL�̏ꍇ�^�O�������Ȃ��Ή�(���l���ڂ�z��)
        IF (iv_value IS NULL) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      ELSIF (ic_type = gc_y) THEN
        --NULL,0�̏ꍇ�^�O�������Ȃ��Ή�(���l���ڂ�z��)
        IF (NVL(iv_value, 0) = 0) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      END IF;
--
      --�C���f�b�N�X
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      lv_work := iv_value;
--
      --�^�O�Z�b�g
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<�^�O��>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<�^�O�̂�>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<�^�O �� �f�[�^>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(lv_work, 0) ; --Null�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := lv_work ;         --Null�ł����̂܂ܕ\��
        END IF;
      END IF;
--
      --�����؂�
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
--
    END prc_set_xml ;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �w�b�_�[�f�[�^���o�E�o�͏���
    -- =====================================================
    -- �w�b�_�[�J�n�^�O
    prc_set_xml('T', 'user_info');
--
    -- ���[�h�c
    prc_set_xml('D', 'report_id', gr_header.report_id);
--
    -- �S���ҕ���
    prc_set_xml('D', 'charge_dept', gr_header.user_dept, 10);
--
    -- �S���Җ�
    prc_set_xml('D', 'agent', gr_header.user_name, 14);
--
    -- �o�͓�
    prc_set_xml('D', 'exec_date', TO_CHAR(gr_header.exec_date,gc_char_dt_format));
--
    -- ���ofrom
    prc_set_xml('D', 'process_year_month_from', gr_header.proc_from_char);
--
    -- ���oto
    prc_set_xml('D', 'process_year_month_to', gr_header.proc_to_char);
--
    -- �w�b�_�[�I���^�O
    prc_set_xml('T','/user_info');
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    --=====================================================
    prc_get_report_data(
        ot_data_rec   => gt_main_data   --    �擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- �f�[�^���J�n�^�O
    prc_set_xml('T', 'data_info');
    --���i�敪
    prc_set_xml('T', 'lg_prod_div');
    prc_set_xml('T', 'g_prod_div');
    prc_set_xml('D', 'arti_div_code', gt_main_data(1).prod_div);
    prc_set_xml('D', 'arti_div_name', gt_main_data(1).prod_div_name, 20);
    --�i�ڋ敪
    prc_set_xml('T', 'lg_item_div');
    prc_set_xml('T', 'g_item_div');
    prc_set_xml('D', 'item_div_code', gt_main_data(1).item_div);
    prc_set_xml('D', 'item_div_name', gt_main_data(1).item_div_name, 20);
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR ln_loop_index IN 1..gt_main_data.COUNT LOOP
      --�\���p�ϐ�������
      ln_std_cost := 0;
      ln_dekikin  := 0;
      ln_dekitan  := 0;
      ln_sai_tan  := 0;
      ln_sai_kin  := 0;
--
      --�L�[���ꔻ�f�p�ϐ�������
      ln_group_depth     := 0;
      lr_now_key.prod_div    := gt_main_data(ln_loop_index).prod_div;
      lr_now_key.item_div    := lr_now_key.prod_div || gt_main_data(ln_loop_index).item_div;
      lr_now_key.crowd_high  := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1);
      lr_now_key.crowd_mid   := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2);
      lr_now_key.crowd_low   := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3);
      lr_now_key.crowd_dtl   := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4);
--
      -- =====================================================
      -- �I���^�O�쐬
      -- =====================================================
      -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
      IF ( lb_isfirst ) THEN
        ln_group_depth := lc_depth_prod_div; --�J�n�^�O�\���p
        lb_isfirst := FALSE;
      ELSE
        --�L�[���ꔻ�f�@�ׂ������ɔ��f
        -- �ڌQ
        IF ( NVL(lr_now_key.crowd_dtl, lc_break ) <> lr_pre_key.crowd_dtl ) THEN
          prc_set_xml('T', '/lg_item');
          prc_set_xml('T', '/g_crowd_dtl');
          ln_group_depth := lc_depth_crowd_dtl;
--
          -- ���Q
          IF ( NVL(lr_now_key.crowd_low, lc_break ) <> lr_pre_key.crowd_low ) THEN
            prc_set_xml('T', '/lg_crowd_dtl');
            prc_set_xml('T', '/g_crowd_low');
            ln_group_depth := lc_depth_crowd_low;
--
            -- ���Q
            IF ( NVL(lr_now_key.crowd_mid, lc_break ) <> lr_pre_key.crowd_mid ) THEN
              prc_set_xml('T', '/lg_crowd_low');
              prc_set_xml('T', '/g_crowd_mid');
              ln_group_depth := lc_depth_crowd_mid;
--
              -- ��Q
              IF ( NVL(lr_now_key.crowd_high, lc_break ) <> lr_pre_key.crowd_high ) THEN
                prc_set_xml('T', '/lg_crowd_mid');
                prc_set_xml('T', '/g_crowd_high');
                ln_group_depth := lc_depth_crowd_high;
--
                -- �i�ڋ敪
                IF ( NVL(lr_now_key.item_div, lc_break ) <> lr_pre_key.item_div ) THEN
                  prc_set_xml('T', '/lg_crowd_high');
                  ln_group_depth := lc_depth_item_div;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- =====================================================
      -- �J�n�^�O�쐬(�傫����
      -- =====================================================
      IF (ln_group_depth >= lc_depth_item_div) THEN
        -- �󕥋敪
        prc_set_xml('T', 'lg_crowd_high');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_high) THEN
        -- ��Q
        prc_set_xml('T', 'g_crowd_high');
        prc_set_xml('D', 'crowd_high'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1));
        prc_set_xml('T', 'lg_crowd_mid');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_mid) THEN
        -- ���Q
        prc_set_xml('T', 'g_crowd_mid');
        prc_set_xml('D', 'crowd_mid'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2));
        prc_set_xml('T', 'lg_crowd_low');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_low) THEN
        -- ���Q
        prc_set_xml('T', 'g_crowd_low');
        prc_set_xml('D', 'crowd_low'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3));
        prc_set_xml('T', 'lg_crowd_dtl');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_dtl) THEN
        -- �ڌQ
        prc_set_xml('T', 'g_crowd_dtl');
        prc_set_xml('D', 'crowd_dtl'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4));
        prc_set_xml('T', 'lg_item');
      END IF;
--
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
--
      --���׊J�n
      prc_set_xml('T', 'g_item');
--
      --�i��
      prc_set_xml('D', 'item_code', gt_main_data(ln_loop_index).item_code);
      prc_set_xml('D', 'item_name', gt_main_data(ln_loop_index).item_name, 20);
--
      --�o����
      --prc_set_xml('D', 'quantity', gt_main_data(ln_loop_index).trans_qty);
      prc_set_xml('D', 'quantity', gt_main_data(ln_loop_index).kan_qty);
--
      --�W������
      IF (gt_main_data(ln_loop_index).trans_qty != 0) THEN
-- 2008/11/19 v1.12 UPDATE START
--        ln_std_cost :=  gt_main_data(ln_loop_index).cmpnt_kin
--                      / gt_main_data(ln_loop_index).trans_qty;
          ln_std_cost :=  gt_main_data(ln_loop_index).cmpnt_cost;
-- 2008/11/19 v1.12 UPDATE END
      END IF;
      prc_set_xml('D', 'standard_cost', ln_std_cost);
--
      --�W�����z
      prc_set_xml('D', 'standard_amount', gt_main_data(ln_loop_index).cmpnt_kin);
--
      --�������z
      prc_set_xml('D', 'turn_amount', gt_main_data(ln_loop_index).tou_kin);
--
      --�ō����z
      prc_set_xml('D', 'hit_amount', gt_main_data(ln_loop_index).uti_kin);
--
      --���Y�����z
      prc_set_xml('D', 'by_product_amount', gt_main_data(ln_loop_index).cmpnt_huku);
--
      --�o�������z
      ln_dekikin :=  gt_main_data(ln_loop_index).tou_kin
-- 2008/12/04 v1.14 DELETE START
--                   + gt_main_data(ln_loop_index).uti_kin
-- 2008/12/04 v1.14 DELETE END
-- 2009/01/16 v1.15 ADD START
                   + gt_main_data(ln_loop_index).uti_kin
-- 2009/01/16 v1.15 ADD END
                   - gt_main_data(ln_loop_index).cmpnt_huku;
      prc_set_xml('D', 'piece_amount', ln_dekikin);
--
      --�o�����P��
      IF (gt_main_data(ln_loop_index).trans_qty != 0 ) THEN
        --ln_dekitan := ln_dekikin / gt_main_data(ln_loop_index).trans_qty ;
-- 2008/11/29 v1.13 UPDATE START
        --ln_dekitan := ln_dekikin / (gt_main_data(ln_loop_index).kan_qty * gt_main_data(ln_loop_index).item_net / gn_thousand) ;
        ln_dekitan := ln_dekikin / gt_main_data(ln_loop_index).kan_qty ;
-- 2008/11/29 v1.13 UPDATE END
      END IF;
      prc_set_xml('D', 'piece_price', ln_dekitan);
--
      --�P������
      ln_sai_tan := ln_std_cost - ln_dekitan;
      prc_set_xml('D', 'difference_price', ln_sai_tan);
--
      --��������
      ln_sai_kin :=  gt_main_data(ln_loop_index).cmpnt_kin - ln_dekikin;
      prc_set_xml('D', 'difference_amount', ln_sai_kin);
--
      -- ���ׂP�s�I��
      prc_set_xml('T', '/g_item');
--
--
      --���㏈��
      lr_pre_key := lr_now_key;
--
      --���v���Z
-- 2008/11/19 v1.12 UPDATE START
--      ln_sum_qty      := ln_sum_qty      + gt_main_data(ln_loop_index).trans_qty;
      ln_sum_qty      := ln_sum_qty      + gt_main_data(ln_loop_index).kan_qty;
-- 2008/11/19 v1.12 UPDATE END
      ln_sum_std_cost := ln_sum_std_cost + ln_std_cost;
      ln_sum_std_kin  := ln_sum_std_kin  + gt_main_data(ln_loop_index).cmpnt_kin;
      ln_sum_tou      := ln_sum_tou      + gt_main_data(ln_loop_index).tou_kin;
      ln_sum_uti      := ln_sum_uti      + gt_main_data(ln_loop_index).uti_kin;
      ln_sum_huku     := ln_sum_huku     + gt_main_data(ln_loop_index).cmpnt_huku;
      ln_sum_dekikin  := ln_sum_dekikin  + ln_dekikin;
      ln_sum_dekitan  := ln_sum_dekitan  + ln_dekitan;
      ln_sum_sai_tan  := ln_sum_sai_tan  + ln_sai_tan;
      ln_sum_sai_kin  := ln_sum_sai_kin  + ln_sai_kin;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I���^�O
    -- =====================================================
    prc_set_xml('T', '/lg_item');
    prc_set_xml('T', '/g_crowd_dtl');
    prc_set_xml('T', '/lg_crowd_dtl');
    prc_set_xml('T', '/g_crowd_low');
    prc_set_xml('T', '/lg_crowd_low');
    prc_set_xml('T', '/g_crowd_mid');
    prc_set_xml('T', '/lg_crowd_mid');
    prc_set_xml('T', '/g_crowd_high');
    prc_set_xml('T', '/lg_crowd_high');
--
    --�󕥃O���[�v���ɍ��v��\��
    prc_set_xml('D', 'switch', 1);
    prc_set_xml('N', 'sum_quantity', ln_sum_qty);
    prc_set_xml('N', 'sum_standard_cost', ln_sum_std_cost);
    prc_set_xml('N', 'sum_standard_amount', ln_sum_std_kin);
    prc_set_xml('N', 'sum_turn_amount', ln_sum_tou);
    prc_set_xml('N', 'sum_hit_amount', ln_sum_uti);
    prc_set_xml('N', 'sum_by_product_amount', ln_sum_huku);
    prc_set_xml('N', 'sum_piece_amount', ln_sum_dekikin);
    prc_set_xml('N', 'sum_piece_price', ln_sum_dekitan);
    prc_set_xml('N', 'sum_difference_price', ln_sum_sai_tan);
    prc_set_xml('N', 'sum_difference_amount', ln_sum_sai_kin);
--
    prc_set_xml('T', '/g_item_div');
    prc_set_xml('T', '/lg_item_div');
    prc_set_xml('T', '/g_prod_div');
    prc_set_xml('T', '/lg_prod_div');
--
    -- �f�[�^���I���^�O
    prc_set_xml('T', '/data_info');
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,'APP-XXCMN-10122'  ) ;
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
  END prc_create_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_from       IN    VARCHAR2  -- �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  -- �����N��TO
     ,iv_prod_div        IN    VARCHAR2  -- ���i�敪
     ,iv_item_div        IN    VARCHAR2  -- �i�ڋ敪
     ,iv_crowd_type      IN    VARCHAR2  -- �W�v���
     ,iv_crowd_code      IN    VARCHAR2  -- �Q�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  -- �o���Q�R�[�h
     ,ov_errbuf          OUT   VARCHAR2   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         OUT   VARCHAR2   -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          OUT   VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- ���̓p�����[�^�ێ�
    gr_param.proc_from       := iv_proc_from      ;-- �����N��FROM
    gr_param.proc_to         := iv_proc_to        ;-- �����N��TO
    gr_param.prod_div        := iv_prod_div       ;-- ���i�敪
    gr_param.item_div        := iv_item_div       ;-- �i�ڋ敪
    gr_param.crowd_type      := iv_crowd_type     ;-- �W�v���
    gr_param.crowd_code      := iv_crowd_code     ;-- �Q�R�[�h
    gr_param.acnt_crowd_code := iv_acnt_crowd_code;-- �o���Q�R�[�h
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode            OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_proc_from       IN    VARCHAR2  -- �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  -- �����N��TO
     ,iv_prod_div        IN    VARCHAR2  -- ���i�敪
     ,iv_item_div        IN    VARCHAR2  -- �i�ڋ敪
     ,iv_crowd_type      IN    VARCHAR2  -- �W�v���
     ,iv_crowd_code      IN    VARCHAR2  -- �Q�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  -- �o���Q�R�[�h
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_proc_from       => iv_proc_from
       ,iv_proc_to         => iv_proc_to
       ,iv_prod_div        => iv_prod_div
       ,iv_item_div        => iv_item_div
       ,iv_crowd_type      => iv_crowd_type
       ,iv_crowd_code      => iv_crowd_code
       ,iv_acnt_crowd_code => iv_acnt_crowd_code
       ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn770007cp ;
/