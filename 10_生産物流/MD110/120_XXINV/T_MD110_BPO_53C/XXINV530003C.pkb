CREATE OR REPLACE PACKAGE BODY xxinv530003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv530003c (body)
 * Description      : �I���\
 * MD.050/070       : �I��Issue1.0 (T_MD050_BPO_530)
                      �I���\Draft1A (T_MD070_BPO_530C)
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  proc_check_param          PROCEDURE : �p�����[�^�E�`�F�b�N(C-1)
 *  proc_get_data             PROCEDURE : �f�[�^�擾(C-2)
 *  proc_create_xml_data      PROCEDURE : �w�l�k�f�[�^�o��(C-4)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : ���[���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-03-06    1.0   T.Ikehara        �V�K�쐬
 *  2008-05-02    1.1   T.Ikehara        �p�����[�^�F�i�ڃR�[�h��i��ID�ɕύX�Ή�
 *  2008-05-02    1.2   T.Ikehara        ���t�o�͌`���A�q�ɃR�[�h�����s��Ή�
 *  2008/06/03    1.3   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/24    1.4   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *
 *****************************************************************************************/
--
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
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_user_expt          EXCEPTION;     -- ���[�U�[�ɂĒ�`��������O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
-- �I���f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD (
      segment1              xxcmn_categories2_v.segment1%TYPE                -- �J�e�S��1
     ,meaning               xxcmn_lookup_values2_v.meaning%TYPE              -- ���e(�i�ڋ敪)
     ,customer_stock_whse   xxcmn_item_locations2_v.customer_stock_whse%TYPE -- ���`
     ,meaning2              xxcmn_lookup_values2_v.meaning%TYPE              -- ���e(�݌ɊǗ����)
     ,invent_whse_code      xxinv_stc_inventory_result.invent_whse_code%TYPE -- �I���q��
     ,whse_name             xxcmn_item_locations2_v.whse_name%TYPE           -- �E�v
     ,item_code             xxinv_stc_inventory_result.item_code%TYPE        -- �i��
     ,item_short_name       xxcmn_item_mst_v.item_short_name%TYPE            -- �i�ڗ���
     ,invent_seq            xxinv_stc_inventory_result.invent_seq%TYPE       -- �I���A��
     ,lot_no                xxinv_stc_inventory_result.lot_no%TYPE           -- ���b�gNo.
     ,maker_date            xxinv_stc_inventory_result.maker_date%TYPE       -- ������
     ,limit_date            xxinv_stc_inventory_result.limit_date%TYPE       -- �ܖ�����
     ,proper_mark           xxinv_stc_inventory_result.proper_mark%TYPE      -- �ŗL�L��
     ,rack_no1              xxinv_stc_inventory_result.rack_no1%TYPE         -- ���b�NNo1
     ,rack_no2              xxinv_stc_inventory_result.rack_no2%TYPE         -- ���b�NNo2
     ,rack_no3              xxinv_stc_inventory_result.rack_no3%TYPE         -- ���b�NNo3
     ,location              xxinv_stc_inventory_result.location%TYPE         -- ���P�[�V����
     ,invent_date           xxinv_stc_inventory_result.invent_date%TYPE      -- �I����
     ,case_amt              xxinv_stc_inventory_result.case_amt%TYPE         -- �I���P�[�X��
     ,content               xxinv_stc_inventory_result.content%TYPE          -- ����
     ,num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE               -- �P�[�X����
     ,loose_amt             xxinv_stc_inventory_result.loose_amt%TYPE        -- �I���o��
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxinv5300003c' ;   -- �p�b�P�[�W��
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gv_param_date_format    CONSTANT VARCHAR2(10) := 'YYYYMM';
  gv_out_date_type        CONSTANT VARCHAR2(20) := 'YYYY/MM/DD' ;
  gv_out_date_year        CONSTANT VARCHAR2(10) := 'YYYY';
  gv_out_date_month       CONSTANT VARCHAR2(10) := 'MM';
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn    CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po     CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- �A�v���P�[�V�����iXXPO�j
  gv_application_xxbpo  CONSTANT VARCHAR2(10) := 'XXBPO';
  gv_msg_xxpo10010      CONSTANT VARCHAR2(20) := 'APP-XXCMN-10010';
  gv_msg_xxpo10122      CONSTANT VARCHAR2(20) := 'APP-XXCMN-10122';
  gv_tkn_param_name     CONSTANT VARCHAR2(20) := 'PARAMETER';
  gv_tkn_param_value    CONSTANT VARCHAR2(100) := 'VALUE';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_user_id             fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  gv_user_dept           xxcmn_locations_all.location_short_name%TYPE DEFAULT NULL;
  gv_user_name           per_all_people_f.per_information18%TYPE DEFAULT NULL;
  gn_case_total          NUMBER DEFAULT 0;   -- �I����(�P�[�X)�W�v
  gn_scatteringly_total  NUMBER DEFAULT 0;   -- �I����(�o��)�W�v
  gn_number_sum_total    NUMBER DEFAULT 0;   -- �I�������v�W�v
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(20) DEFAULT NULL;  -- ���[ID
  gd_exec_date              DATE  DEFAULT NULL;         -- ���{��
  gt_main_data              tab_data_type_dtl ;         -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                  -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER  DEFAULT 0;          -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  gv_item_name              xxcmn_categories_v.category_set_name%TYPE DEFAULT  '*';
  gv_stock_whse_name        xxcmn_lookup_values2_v.meaning%TYPE DEFAULT  '*';
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
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
    lv_convert_data         VARCHAR2(2000)  DEFAULT NULL;
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
  /**********************************************************************************
   * Procedure Name   : proc_check_param
   * Description      : C-1.�p�����[�^�[�E�`�F�b�N
   ***********************************************************************************/
  PROCEDURE proc_check_param(
     ov_errbuf             OUT     VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT     VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT     VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_inventory_time     IN      VARCHAR2    -- 1.�I���N���x
    ,iv_stock_name         IN      VARCHAR2    -- 2.���`
    ,iv_report_post        IN      VARCHAR2    -- 3.�񍐕���
    ,iv_warehouse_code     IN      VARCHAR2    -- 4.�q�ɃR�[�h
    ,iv_distribution_block IN      VARCHAR2    -- 5.�u���b�N
    ,iv_item_type          IN      VARCHAR2    -- 6.�i�ڋ敪
    ,iv_item_code          IN      VARCHAR2    -- 7.�i�ڃR�[�h
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check_param'; -- �v���O������
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
    cv_lookup_type_ctrl       CONSTANT VARCHAR2(20)  := 'XXCMN_INV_CTRL';
    cv_lookup_type_d12        CONSTANT VARCHAR2(20)  := 'XXCMN_D12';
    cv_param_inv_time         CONSTANT VARCHAR2(20)  := '�I���N���x';
    cv_param_stock_name       CONSTANT VARCHAR2(20)  := '���`';
    cv_param_report_post      CONSTANT VARCHAR2(20)  := '�񍐕���';
    cv_param_warehouse_code   CONSTANT VARCHAR2(20)  := '�q�ɃR�[�h';
    cv_param_block            CONSTANT VARCHAR2(20)  := '�u���b�N';
    cv_param_item_type        CONSTANT VARCHAR2(20)  := '�i�ڋ敪';
    cv_param_item_code        CONSTANT VARCHAR2(20)  := '�i�ڃR�[�h';
--
    -- *** ���[�J���ϐ� ***
    lv_check_whse      ic_whse_mst.whse_code%TYPE DEFAULT NULL;
    lv_palam_check     xxcmn_lookup_values_v.lookup_code%TYPE DEFAULT NULL;
    ln_category_id     xxcmn_categories2_v.category_id%TYPE DEFAULT NULL;
    ln_palam_check     NUMBER  DEFAULT NULL;
    lv_date_check      VARCHAR2(20)  DEFAULT NULL;
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
  -- �p�����[�^�`�F�b�N.�I���N���x
    lv_date_check := FND_DATE.STRING_TO_DATE(iv_inventory_time, gv_param_date_format);
--
    IF (lv_date_check IS NULL) THEN
      lv_errbuf  := xxcmn_common_pkg.get_msg(
                      iv_application  => gc_application_cmn,
                      iv_name         => gv_msg_xxpo10010,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => cv_param_inv_time,
                      iv_token_name2  => gv_tkn_param_value,
                      iv_token_value2 => iv_inventory_time
                    );
      lv_retcode := gv_status_error;
      RAISE global_user_expt;
    END IF;
--
  -- �p�����[�^�`�F�b�N.���`
    BEGIN
      SELECT
        xlvv2.meaning  AS meaning
      INTO
        gv_stock_whse_name
      FROM    xxcmn_lookup_values2_v xlvv2            -- �N�C�b�N�R�[�h���VIEW
      WHERE   xlvv2.lookup_code = iv_stock_name
        AND   xlvv2.lookup_type = cv_lookup_type_ctrl;
--
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gc_application_cmn,
                        iv_name         => gv_msg_xxpo10010,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => cv_param_stock_name,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_stock_name
                      );
        RAISE global_user_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  -- �p�����[�^�`�F�b�N.�񍐕���
    BEGIN
      SELECT  xl2v.location_id  AS location_id
      INTO    ln_palam_check
      FROM    xxcmn_locations2_v  xl2v
      WHERE   location_code = iv_report_post
        AND   ROWNUM = 1;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gc_application_cmn,
                        iv_name         => gv_msg_xxpo10010,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => cv_param_report_post,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_report_post
                      );
        RAISE global_user_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  -- �p�����[�^�`�F�b�N.�q�ɃR�[�h
    IF (iv_warehouse_code IS NOT NULL) THEN
      BEGIN
        SELECT  iwm.whse_code    AS whse_code
        INTO    lv_check_whse
        FROM    ic_whse_mst       iwm
        WHERE   iwm.whse_code = iv_warehouse_code
          AND   iwm.attribute1 = iv_stock_name
          AND   ROWNUM = 1;
      EXCEPTION
      -- �f�[�^���Ȃ��ꍇ�̓G���[
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gc_application_cmn,
                          iv_name         => gv_msg_xxpo10010,
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => cv_param_warehouse_code,
                          iv_token_name2  => gv_tkn_param_value,
                          iv_token_value2 => iv_warehouse_code
                        );
          RAISE global_user_expt;
        WHEN OTHERS THEN
          RAISE;
      END;
    END IF;
--
  -- �p�����[�^�`�F�b�N.�u���b�N
    IF (iv_distribution_block IS NOT NULL) THEN
      BEGIN
        SELECT  xlvv2.lookup_code AS lookup_code
        INTO    lv_palam_check
        FROM    xxcmn_lookup_values2_v  xlvv2
        WHERE   xlvv2.lookup_code = iv_distribution_block
          AND   xlvv2.lookup_type = cv_lookup_type_d12;
      EXCEPTION
      -- �f�[�^���Ȃ��ꍇ�̓G���[
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gc_application_cmn,
                          iv_name         => gv_msg_xxpo10010,
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => cv_param_block,
                          iv_token_name2  => gv_tkn_param_value,
                          iv_token_value2 => iv_distribution_block
                        );
          RAISE global_user_expt;
        WHEN OTHERS THEN
          RAISE;
      END;
    END IF;
--
  -- �p�����[�^�`�F�b�N.�i�ڋ敪
    BEGIN
      SELECT
        xcv2.description AS description,
        xcv2.category_id  AS category_id
      INTO
        gv_item_name,
        ln_category_id
      FROM    xxcmn_categories2_v  xcv2
      WHERE   xcv2.segment1 = iv_item_type
        AND   xcv2.category_set_name = cv_param_item_type;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gc_application_cmn,
                        iv_name         => gv_msg_xxpo10010,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => cv_param_item_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_item_type
                      );
        RAISE global_user_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  -- �p�����[�^�`�F�b�N.�i�ڃR�[�h
    IF (iv_item_code IS NOT NULL) THEN
      BEGIN
        SELECT  ximv2.item_id  AS item_id
        INTO    ln_palam_check
        FROM    xxcmn_item_mst2_v    ximv2,
                xxcmn_item_categories2_v  xicv2
        WHERE   ximv2.item_id = xicv2.item_id
          AND   xicv2.category_id = ln_category_id
          AND   ximv2.item_id = iv_item_code;
      EXCEPTION
      -- �f�[�^���Ȃ��ꍇ�̓G���[
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gc_application_cmn,
                          iv_name         => gv_msg_xxpo10010,
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => cv_param_item_code,
                          iv_token_name2  => gv_tkn_param_value,
                          iv_token_value2 => iv_item_code
                        );
          RAISE global_user_expt;
      END;
    END IF;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      -- ���O�Ƀp�����[�^�E�G���[���b�Z�[�W���o�͂���
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_check_param;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : C-2.�f�[�^�擾
   ***********************************************************************************/
  PROCEDURE proc_get_data(
     ov_errbuf             OUT     VARCHAR2   -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT     VARCHAR2   -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT     VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_inventory_time     IN      VARCHAR2   -- 1.�I���N���x
    ,iv_stock_name         IN      VARCHAR2   -- 2.���`
    ,iv_report_post        IN      VARCHAR2   -- 3.�񍐕���
    ,iv_warehouse_code     IN      VARCHAR2   -- 4.�q�ɃR�[�h
    ,iv_distribution_block IN      VARCHAR2   -- 5.�u���b�N
    ,iv_item_type          IN      VARCHAR2   -- 6.�i�ڋ敪
    ,iv_item_code          IN      VARCHAR2   -- 7.�i�ڃR�[�h
    ,ot_data_rec           OUT     NOCOPY tab_data_type_dtl  -- �擾�f�[�^�i�[�p
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data'; -- �v���O������
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
    -- �������o�͕��@(DFF)
    cv_date_type        CONSTANT VARCHAR2(10) := 'YYYYMM';          -- ���t�^
    cv_quickcode_ctrl   CONSTANT VARCHAR2(20) := 'XXCMN_INV_CTRL';  -- �N�C�b�N�R�[�h(�݌ɊǗ����)
    cv_item_type        CONSTANT VARCHAR2(10) := '�i�ڋ敪';        -- �J�e�S���Z�b�g��
    cv_item_type_order  CONSTANT VARCHAR2(1)  := '5';               -- �i�ڃ^�C�v(����)
--
    -- *** ���[�J���ϐ� ***
    lv_req_number         VARCHAR2(100) DEFAULT NULL;      -- �w���˗��ԍ�
    ld_request_date       DATE DEFAULT NULL;               -- �v����
    ln_order_number       NUMBER DEFAULT 0 ;               -- �󒍔ԍ�
    lv_party_site_number  VARCHAR2(30) DEFAULT NULL;       -- �ڋq�T�C�g�R�[�h
    lv_manag_office_code  VARCHAR2(200) DEFAULT NULL;      -- �Ǘ��������R�[�h
    lv_department_code    VARCHAR2(10) DEFAULT NULL;       -- BOM����R�[�h
    lv_terms_flg          VARCHAR2(1) DEFAULT NULL;        -- �����t���O
    ld_object_date        DATE DEFAULT NULL;               -- �I����(��������)
    ld_next_date          DATE DEFAULT NULL;               -- �I����(��������)
    lv_sql                VARCHAR2(32767) DEFAULT NULL;    -- ���ISQL��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    TYPE   ref_cursor IS REF CURSOR ;
    cur_main_data ref_cursor ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    lv_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--�I���Ώۊ��Ԏ擾
    ld_object_date := FND_DATE.STRING_TO_DATE(iv_inventory_time,cv_date_type);
    ld_next_date := FND_DATE.STRING_TO_DATE(iv_inventory_time + 1,cv_date_type);
--
    lv_sql :=
         'SELECT'
      || '   xcv2.segment1                 AS segment1'               -- �J�e�S��1
      || ' ,xcv2.description               AS description'            -- ���e�i�i�ڋ敪�j
      || ' ,iwm.attribute1                 AS customer_stock_whse'    -- ���`
      || ' ,xlvv2.meaning                  AS meaning'                -- ���e�i�݌ɊǗ���́j
      || ' ,xsir.invent_whse_code          AS invent_whse_code'       -- �I���q��
      || ' ,iwm.whse_name                  AS whse_name'              -- �q�ɖ���
      || ' ,xsir.item_code                 AS item_code'              -- �i��
      || ' ,ximv.item_short_name           AS item_short_name'        -- ����
      || ' ,xsir.invent_seq                AS invent_seq'             -- �I���A��
      || ' ,xsir.lot_no                    AS lot_no'                 -- ���b�gNo.
      || ' ,xsir.maker_date                AS maker_date'             -- ������
      || ' ,xsir.limit_date                AS limit_date'             -- �ܖ�����
      || ' ,xsir.proper_mark               AS proper_mark'            -- �ŗL�L��
      || ' ,xsir.rack_no1                  AS rack_no1'               -- ���b�NNo1
      || ' ,xsir.rack_no2                  AS rack_no2'               -- ���b�NNo2
      || ' ,xsir.rack_no3                  AS rack_no3'               -- ���b�NNo3
      || ' ,xsir.location                  AS location'               -- ���P�[�V����
      || ' ,xsir.invent_date               AS invent_date'            -- �I����
      || ' ,xsir.case_amt                  AS case_amt'               -- �I���P�[�X��
      || ' ,xsir.content                   AS content'                -- ����
      || ' ,ximv.num_of_cases              AS num_of_cases'           -- �P�[�X����
      || ' ,xsir.loose_amt                 AS loose_amt '             -- �I���o��
--FROM��ҏW
      || 'FROM'
      || ' xxinv_stc_inventory_result    xsir'    -- �I�����ʃe�[�u��
      || ',ic_whse_mst                   iwm'     -- OPM�q�Ƀ}�X�^
      || ',xxcmn_item_mst2_v             ximv'    -- OPM�i�ڏ��VIEW2
      || ',xxcmn_item_categories2_v      xicv'    -- OPM�i�ڃJ�e�S���������VIEW2
      || ',xxcmn_categories2_v           xcv2'    -- �i�ڃJ�e�S�����VIEW2
      || ',xxcmn_lookup_values2_v        xlvv2 '  -- �N�C�b�N�R�[�h���VIEW2
--WHERE��ҏW
      || 'WHERE'
      || ' (xsir.invent_date >= ''' || ld_object_date  || ''''
      || '   AND xsir.invent_date < ''' || ld_next_date || ''')'
      || ' AND xsir.invent_whse_code = iwm.whse_code '
      || ' AND ximv.item_id = xsir.item_id '
      || ' AND ((ximv.start_date_active <= xsir.invent_date) '
      || '   AND (ximv.end_date_active >=xsir.invent_date))'
      || ' AND iwm.attribute1 = ''' || iv_stock_name || ''''
      || ' AND xlvv2.lookup_type = ''' || cv_quickcode_ctrl || ''''
      || ' AND xlvv2.lookup_code = iwm.attribute1'
      || ' AND xcv2.category_id =  xicv.category_id '
      || ' AND xcv2.category_set_name = ''' || cv_item_type || ''''
      || ' AND xcv2.segment1 = ''' || iv_item_type || ''''
      || ' AND xsir.report_post_code = ''' || iv_report_post || ''''
      || ' AND xsir.item_id = xicv.item_id';
--�y���̓p�����[�^�F�q�ɃR�[�h�����͍ς̏ꍇ�z
    IF (iv_warehouse_code IS NOT NULL) THEN
      lv_sql := lv_sql
        || ' AND iwm.whse_code = ''' || iv_warehouse_code || '''';
    END IF;
--�y���̓p�����[�^�F�u���b�N�����͍ς̏ꍇ�z
    IF (iv_distribution_block IS NOT NULL) THEN
      lv_sql := lv_sql
        || ' AND EXISTS(SELECT  ilm.whse_code'
        || '        FROM   ic_loct_mst         ilm'
        || '              ,mtl_item_locations  mil '
        || '        WHERE ilm.whse_code = iwm.whse_code '
        || '          AND ilm.inventory_location_id = mil.inventory_location_id '
        || '          AND mil.attribute6 = ''' || iv_distribution_block || ''')';
    END IF;
--�y���̓p�����[�^�F�i�ڂ����͍ς̏ꍇ�z
    IF (iv_item_code IS NOT NULL) THEN
      lv_sql := lv_sql
        || ' AND ximv.item_id = ' || iv_item_code;
    END IF;
--ORDER BY��ҏW
    lv_sql := lv_sql
      || ' ORDER BY'
      || ' xsir.invent_whse_code'
      || ',xsir.item_code';
    IF (iv_item_type = cv_item_type_order) THEN
      lv_sql := lv_sql
        || ',xsir.maker_date'
        || ',xsir.proper_mark';
    ELSE
    lv_sql := lv_sql
      || ',xsir.lot_no';
    END IF;
    lv_sql := lv_sql
      || ',xsir.invent_seq';
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_main_data FOR lv_sql ;
    -- �o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE cur_main_data ;
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
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_create_xml_data
   * Description      : C-4.�w�l�k�f�[�^�o��
   **********************************************************************************/
  PROCEDURE proc_create_xml_data(
     ov_errbuf             OUT     VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT     VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT     VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_inventory_time     IN      VARCHAR2    -- 1.�I���N���x
    ,iv_stock_name         IN      VARCHAR2    -- 2.���`
    ,iv_report_post        IN      VARCHAR2    -- 3.�񍐕���
    ,iv_warehouse_code     IN      VARCHAR2    -- 4.�q�ɃR�[�h
    ,iv_distribution_block IN      VARCHAR2    -- 5.�u���b�N
    ,iv_item_type          IN      VARCHAR2    -- 6.�i�ڋ敪
    ,iv_item_code          IN      VARCHAR2    -- 7.�i�ڃR�[�h
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_create_xml_data'; -- �v���O������
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
    -- �L�[�u���C�N���f�p
    lc_break_init           VARCHAR2(100) := '*' ;   -- �����l
    lc_break_null           VARCHAR2(100) := '**' ;  -- NULL����
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_whse_class         VARCHAR2(100) DEFAULT '*' ;  -- �q�ɃR�[�h
    lv_item_class         VARCHAR2(100) DEFAULT '*' ;  -- �i��
--
    ln_pac_cases          NUMBER(20)    DEFAULT 0 ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    proc_get_data(
       ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W
      ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h
      ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_inventory_time     => iv_inventory_time      -- 1.�I���N���x
      ,iv_stock_name         => iv_stock_name          -- 2.���`
      ,iv_report_post        => iv_report_post         -- 3.�񍐕���
      ,iv_warehouse_code     => iv_warehouse_code      -- 4.�q�ɃR�[�h
      ,iv_distribution_block => iv_distribution_block  -- 5.�u���b�N
      ,iv_item_type          => iv_item_type           -- 6.�i�ڋ敪
      ,iv_item_code          => iv_item_code           -- 7.�i�ڃR�[�h
      ,ot_data_rec           => gt_main_data);         -- �擾�f�[�^�i�[�p�z��
--
    IF ( gt_main_data.COUNT = 0 ) THEN
      lv_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                      iv_application  => gc_application_cmn,
                      iv_name         => gv_msg_xxpo10122
                    );
      RAISE global_user_expt ;
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
      -- ���[�h�c
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
      -- ���{��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gd_exec_date, gc_char_dt_format) ;
      -- �S��(������)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_user_dept, 0, 10) ;
      -- �S��(����)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_user_name, 0, 14) ;
      -- �I���N���x(�N)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_year' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(iv_inventory_time, gv_param_date_format), gv_out_date_year);
      -- �I���N���x(��)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_month' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(iv_inventory_time, gv_param_date_format), gv_out_date_month);
      -- �i�ڋ敪�R�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_division_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := iv_item_type ;
      -- �i�ڋ敪����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_division_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_item_name, 0, 6) ;
      -- ���`
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'nominal' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_stock_whse_name, 0, 22) ;
    -- -----------------------------------------------------
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- ���׃f�[�^�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- �q�ɃR�[�h�u���C�N
      -- =====================================================
      -- �q�ɃR�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).invent_whse_code, lc_break_null ) <> lv_whse_class ) THEN
        --���iG�I���^�O���f�p�ϐ�������
        lv_item_class := lc_break_init;
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_whse_class <> lc_break_init ) THEN
          ------------------------------
          -- ���i�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���iL�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �q�ɂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_warehouse' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �q��L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_warehouse' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �q��L�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_warehouse' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �q�ɂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_warehouse' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �q�ɂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �q�ɃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'warehouse_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=  gt_main_data(i).invent_whse_code;
        -- �q�ɖ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'warehouse_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).whse_name, 0, 20) ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_whse_class  := NVL( gt_main_data(i).invent_whse_code, lc_break_null )  ;
      END IF;
--
      -- =====================================================
      -- ���i�R�[�h�u���C�N
      -- =====================================================
      -- ���i�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).item_code, lc_break_null ) <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- ���i�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���iL�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- -----------------------------------------------------
        -- ���iL�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���i�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���i�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���i�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=  gt_main_data(i).item_code;
        -- ���i����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).item_short_name, 0,20);
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_class  := NVL( gt_main_data(i).item_code, lc_break_null )  ;
      END IF;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
--
      -- -----------------------------------------------------
      -- ���ׂk�f�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- �I���A��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_consecutive_numbers' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).invent_seq ;
      -- ���b�gNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_number' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).lot_no ;
      -- �����N����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'wip_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).maker_date, gv_out_date_type), gv_out_date_type);
      -- �ܖ�����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'best_before_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).limit_date, gv_out_date_type), gv_out_date_type);
      -- �ŗL�L��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'peculiar_mark' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).proper_mark, 0, 6) ;
      -- ���b�NNo1
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rack_no1' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).rack_no1 ;
      -- ���b�NNo2
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rack_no2' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).rack_no2 ;
      -- ���b�NNo3
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rack_no3' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).rack_no3 ;
      -- ���P�[�V����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'location' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).location, 0, 10) ;
      -- �I����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value :=
        TO_CHAR(gt_main_data(i).invent_date, gv_out_date_type) ;
      -- �I����(�P�[�X)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_number_case' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).case_amt ;
      -- �I����(�P�[�X)�W�v
      gn_case_total := gn_case_total + gt_main_data(i).case_amt;
      -- ����
      IF (gt_main_data(i).content != 0) THEN
        ln_pac_cases := gt_main_data(i).content;
      ELSE
        ln_pac_cases := NVL(gt_main_data(i).num_of_cases, 0);
      END IF;
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'purchase_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_pac_cases;
      -- �I����(�o��)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_number_scatteringly' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).loose_amt ;
      -- �I����(�o��)�W�v
      gn_scatteringly_total := gn_scatteringly_total + gt_main_data(i).loose_amt;
      -- �I�������v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_number_sum' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value :=
        (gt_main_data(i).case_amt *ln_pac_cases + gt_main_data(i).loose_amt) ;
      -- �I�������v�W�v
      gn_number_sum_total := gn_number_sum_total +
        (gt_main_data(i).case_amt *ln_pac_cases + gt_main_data(i).loose_amt);
--
      -- -----------------------------------------------------
      -- ���ׂf�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂk�f�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    ------------------------------
    -- ���i�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���i�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �W�v�I�����o��
    -- �I����(�P�[�X)�����v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'number_case_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gn_case_total ;
    -- �I����(�o��)�����v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'number_scatteringly_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gn_scatteringly_total ;
    -- �I���������v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'number_sum_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gn_number_sum_total ;
    ------------------------------
    -- �q�ɂf�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_warehouse' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �q��L�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_warehouse' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
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
  END proc_create_xml_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT     VARCHAR2,   -- �G���[�E���b�Z�[�W
    ov_retcode            OUT     VARCHAR2,   -- ���^�[���E�R�[�h
    ov_errmsg             OUT     VARCHAR2,   -- ���[�U�[�E�G���[�E���b�Z�[�W
    iv_inventory_time     IN      VARCHAR2,   -- 1.�I���N���x
    iv_stock_name         IN      VARCHAR2,   -- 2.���`
    iv_report_post        IN      VARCHAR2,   -- 3.�񍐕���
    iv_warehouse_code     IN      VARCHAR2,   -- 4.�q�ɃR�[�h
    iv_distribution_block IN      VARCHAR2,   -- 5.�u���b�N
    iv_item_type          IN      VARCHAR2,   -- 6.�i�ڋ敪
    iv_item_code          IN      VARCHAR2    -- 7.�i�ڃR�[�h
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_podate_cnt     NUMBER DEFAULT 0;          -- �����f�[�^��������
    ln_data_cnt       NUMBER DEFAULT 0;          -- ��������
    lv_xml_string     VARCHAR2(32000) ;
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
    --��������
    gv_report_id              := 'XXINV530003T';                  -- ���[ID
    gv_user_dept              := xxcmn_common_pkg.get_user_dept(gv_user_id);
    gv_user_name              := xxcmn_common_pkg.get_user_name(gv_user_id);
    gd_exec_date              := SYSDATE ;            -- ���{��
--
    -- ===============================
    -- 1.�p�����[�^�[�E�`�F�b�N
    -- ===============================
    proc_check_param(
       ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W
      ,ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h
      ,ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_inventory_time     => iv_inventory_time       -- 1.�I���N���x
      ,iv_stock_name         => iv_stock_name           -- 2.���`
      ,iv_report_post        => iv_report_post          -- 3.�񍐕���
      ,iv_warehouse_code     => iv_warehouse_code       -- 4.�q�ɃR�[�h
      ,iv_distribution_block => iv_distribution_block   -- 5.�u���b�N
      ,iv_item_type          => iv_item_type            -- 6.�i�ڋ敪
      ,iv_item_code          => iv_item_code);          -- 7.�i�ڃR�[�h
--
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 3.�w�l�k�f�[�^�o��
    -- ===============================
    proc_create_xml_data(
       ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W
      ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h
      ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_inventory_time     => iv_inventory_time      -- 1.�I���N���x
      ,iv_stock_name         => iv_stock_name          -- 2.���`
      ,iv_report_post        => iv_report_post         -- 3.�񍐕���
      ,iv_warehouse_code     => iv_warehouse_code      -- 4.�q�ɃR�[�h
      ,iv_distribution_block => iv_distribution_block  -- 5.�u���b�N
      ,iv_item_type          => iv_item_type           -- 6.�i�ڋ敪
      ,iv_item_code          => iv_item_code);         -- 7.�i�ڃR�[�h
--
    -- �G���[����
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
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
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ���[�o�̓t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    ov_errbuf             OUT     VARCHAR2,   -- �G���[�E���b�Z�[�W
    ov_retcode            OUT     VARCHAR2,   -- ���^�[���E�R�[�h
    iv_inventory_time     IN      VARCHAR2,   -- 1.�I���N���x
    iv_stock_name         IN      VARCHAR2,   -- 2.���`
    iv_report_post        IN      VARCHAR2,   -- 3.�񍐕���
    iv_warehouse_code     IN      VARCHAR2,   -- 4.�q�ɃR�[�h
    iv_distribution_block IN      VARCHAR2,   -- 5.�u���b�N
    iv_item_type          IN      VARCHAR2,   -- 6.�i�ڋ敪
    iv_item_code          IN      VARCHAR2    -- 7.�i�ڃR�[�h
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf             => lv_errbuf,               -- �G���[�E���b�Z�[�W
      ov_retcode            => lv_retcode,              -- ���^�[���E�R�[�h
      ov_errmsg             => lv_errmsg,               -- ���[�U�[�E�G���[�E���b�Z�[�W
      iv_inventory_time     => iv_inventory_time,       -- 1.�I���N���x
      iv_stock_name         => iv_stock_name,           -- 2.���`
      iv_report_post        => iv_report_post,          -- 3.�񍐕���
      iv_warehouse_code     => iv_warehouse_code,       -- 4.�q�ɃR�[�h
      iv_distribution_block => iv_distribution_block,   -- 5.�u���b�N
      iv_item_type          => iv_item_type,            -- 6.�i�ڋ敪
      iv_item_code          => iv_item_code);           -- 7.�i�ڃR�[�h
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      ov_errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    ov_retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv530003c;
/
