CREATE OR REPLACE PACKAGE BODY XXINV550003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550003C(body)
 * Description      : �v��E�ړ��E�݌ɁF�݌�(���[)
 * MD.050/070       : T_MD050_BPO_550_�݌�(���[)Issue1.0 (T_MD050_BPO_550)
 *                  : �U�֖��ו\                         (T_MD070_BPO_55C)
 * Version          : 1.0
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  prc_check_param_info        �p�����[�^�`�F�b�N(C-1)
 *  funk_item_ctl_chk           �i�ڂ̃p�����[�^���փ`�F�b�N (C1)
 *  prc_get_prod_pay_data       PROD:���Y���o�f�[�^�擾�v���V�[�W��(C2)
 *  prc_get_prod_rcv_data       PROD:���Y����f�[�^�擾�v���V�[�W��(C2)
 *  prc_get_adji_data           ADJI:�݌ɒ���(��)�f�[�^�擾�v���V�[�W��(C2)
 *  prc_get_omso_porc_data      OSMO:���{�o��/�p�� PORC�RMA:���{�o�Ɏ��/�p�����(C2)
 *  prc_get_data_to_tmp_table   �f�[�^���H�E���ԃe�[�u���X�V�v���V�[�W��(C2)
 *  prc_get_data_from_tmp_table �f�[�^�擾(�ŏI�o�̓f�[�^)�v���V�[�W��(C2)
 *  prc_create_xml_data         �w�l�k�f�[�^�쐬(C-3/C-4)
 *  convert_into_xml            XML�f�[�^�ϊ�
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/18     1.0  Yusuke Tabata    �V�K�쐬
 *  2008/5/06     1.1  Yusuke Tabata    �ύX�v���Ή�(Seq7/31)
 *                                      �����ύX�v���Ή�(Seq)
 *  2008/6/03     1.2  Takao Ohashi     �����e�X�g�s�
 *  2008/6/06     1.3  Takao Ohashi     �����e�X�g�s�
 *  2008/6/17     1.4  Kazuo Kumamoto   �����e�X�g�s�(�\�[�g���ύX�E��������̓`�[�͐�ɏo��)
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
--################################  �Œ蕔 END   ###############################
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
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXINV550003C' ;   -- �p�b�P�[�W��
  gc_report_id              CONSTANT VARCHAR2(12) := 'XXINV550003T' ;   -- ���[ID
  gc_language_code          CONSTANT VARCHAR2(2)  := 'JA' ;             -- ����LANGUAGE_CODE
--
  -- OPM�i�ڃJ�e�S�������F�i�ڋ敪
  gc_item_ctl_mtl           CONSTANT VARCHAR2(1)  := '1';               -- ����
  gc_item_ctl_haif_prd      CONSTANT VARCHAR2(1)  := '4';               -- �����i
  gc_item_ctl_prd           CONSTANT VARCHAR2(1)  := '5';               -- ���i
  -- OPM�i�ڃJ�e�S�������F�J�e�S����
  gc_category_name_item_ctl CONSTANT VARCHAR2(8)  := '�i�ڋ敪' ;       -- �i�ڋ敪
  -- OPM�ۗ��݌Ƀg�����U�N�V�����F���C���^�C�v
  gc_line_type_pay          CONSTANT NUMBER       := -1 ;               -- ��
  gc_line_type_rcv          CONSTANT NUMBER       :=  1 ;               -- ��
  -- OPM�ۗ��݌Ƀg�����U�N�V�����F�����t���O
  gc_comp_ind_on            CONSTANT NUMBER       :=  1 ;               -- ����
  -- �󕥋敪�A�h�I���}�X�^�F�����^�C�v
  gc_doc_type_prod          CONSTANT VARCHAR2(4)  :='PROD' ;            -- ���Y
  gc_doc_type_adji          CONSTANT VARCHAR2(4)  :='ADJI' ;            -- �݌ɒ���
  gc_doc_type_omso          CONSTANT VARCHAR2(4)  :='OMSO' ;            -- ���{�o��
  gc_doc_type_porc          CONSTANT VARCHAR2(4)  :='PORC' ;            -- �p��(�o��)
  -- �󕥋敪�A�h�I���}�X�^�F�\�[�X�����^�C�v
  gc_source_doc_type_rma    CONSTANT VARCHAR2(4)  :='RMA' ;             -- ���Y
  -- �󕥋敪�A�h�I���}�X�^�F���o�i�ڋ敪
  gc_item_class_code_1      CONSTANT VARCHAR2(1)  := '1' ;              -- ����
  gc_item_class_code_4      CONSTANT VARCHAR2(1)  := '4' ;              -- �����i
  gc_item_class_code_5      CONSTANT VARCHAR2(1)  := '5' ;              -- ���i
  -- �󕥋敪�A�h�I���}�X�^�F�݌ɒ��[�g�p�敪
  gc_use_div_invent_rep     CONSTANT VARCHAR2(1)  := 'Y' ;              -- �g�p
  -- �󕥋敪�A�h�I���}�X�^�F�݌ɒ����敪
  gc_stock_adjst_div_sa     CONSTANT VARCHAR2(1)  := '2' ;              -- �݌ɒ���
  -- GME���Y�o�b�`�w�b�_�F�o�b�`�X�e�[�^�X
  gc_batch_status_close     CONSTANT VARCHAR2(1)  := '4' ;              -- �N���[�Y��
  -- �H���}�X�^�F�H���敪
  gc_routing_class_61       CONSTANT VARCHAR2(2)  :='61' ;              -- �ԕi����
  gc_routing_class_62       CONSTANT VARCHAR2(2)  :='62' ;              -- ��̔����i
  gc_routing_class_70       CONSTANT VARCHAR2(2)  :='70' ;              -- �i�ڐU��
  -- OPM�i�ڏ��VIEW2�F�����Ǘ��敪
  gc_cost_manage_code_n     CONSTANT VARCHAR2(1)  := '1' ;              -- �����Ǘ�:�W��
  gc_cost_manage_code_j     CONSTANT VARCHAR2(1)  := '0' ;              -- �����Ǘ�:����
  -- �W������VIEW�F����0
  gc_cost_0                 CONSTANT NUMBER       := 0 ;                -- �o�͗p�F0�~
  -- �N�C�b�N�R�[�h:�Q�ƃ^�C�v�R�[�h
  gc_lookup_type_new_div    CONSTANT VARCHAR2(18) := 'XXCMN_NEW_DIVISION' ; -- �V�敪
  gc_apl_code               CONSTANT VARCHAR2(3)  := 'FND' ;                -- �N�C�b�N�R�[�h�p
  -- ���t�^�}�X�N
  gc_date_mask              CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- ���t�^�}�X�N
  gc_date_mask_s            CONSTANT VARCHAR2(21) := 'YYYY/MM/DD' ;            -- ���t�^�}�X�N
  gc_date_mask_jp           CONSTANT VARCHAR2(19) := 'YYYY"�N"MM"��"DD"��' ;   -- ���t�^�}�X�N(�N����)
  -- ���b�Z�[�W
  gc_application_cmn        CONSTANT VARCHAR2(5)  := 'XXCMN' ;           -- �A�h�I���F�}�X�^�E�o���E����
  gc_err_code_data_0        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ; -- �f�[�^�O�����b�Z�[�W
  gc_application_inv        CONSTANT VARCHAR2(5)  := 'XXINV' ;           -- �A�h�I���F�v��E�ړ��E�݌�
  gc_err_code_unt_valid     CONSTANT VARCHAR2(15) := 'APP-XXINV-10155' ; -- �i�ڋ敪�w��G���[
  gc_err_code_dpnd_valid    CONSTANT VARCHAR2(15) := 'APP-XXINV-10156' ; -- �i�ڋ敪���փG���[
  -- �o��
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
  -- �v���t�@�C��
  gc_routing_class          CONSTANT VARCHAR2(19) := 'XXINV_DUMMY_ROUTING' ;          -- �i�ڐU��
  gc_routing_class_ret      CONSTANT VARCHAR2(23) := 'XXINV_DUMMY_ROUTING_RET' ;      -- �ԕi����
  gc_routing_class_separate CONSTANT VARCHAR2(29) := 'XXINV_DUMMY_ROUTING_SEPARATE' ; -- ��̔����i
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
       date_from           gme_batch_header.actual_cmplt_date%TYPE            -- 01 : �N����_FROM
      ,date_to             gme_batch_header.actual_cmplt_date%TYPE            -- 02 : �N����_TO
      ,out_item_ctl        xxcmn_lookup_values_v.lookup_code%TYPE             -- 03 : ���o�i�ڋ敪
      ,item1               xxcmn_item_mst_v.item_id%TYPE                      -- 04 : �i�ڃR�[�h1
      ,item2               xxcmn_item_mst_v.item_id%TYPE                      -- 05 : �i�ڃR�[�h2
      ,item3               xxcmn_item_mst_v.item_id%TYPE                      -- 06 : �i�ڃR�[�h3
      ,reason_code         xxcmn_lookup_values_v.lookup_code%TYPE             -- 07 : ���R�R�[�h
      ,item_location_id    xxcmn_item_locations_v.inventory_location_id%TYPE  -- 08 : �ۊǑq��ID
      ,dept_id             xxcmn_locations_v.location_id%TYPE                 -- 09 : �S������ID
      ,entry_no1           gme_batch_header.batch_no%TYPE                     -- 10 : �`�[No1
      ,entry_no2           gme_batch_header.batch_no%TYPE                     -- 11 : �`�[No2
      ,entry_no3           gme_batch_header.batch_no%TYPE                     -- 12 : �`�[No3
      ,entry_no4           gme_batch_header.batch_no%TYPE                     -- 13 : �`�[No4
      ,entry_no5           gme_batch_header.batch_no%TYPE                     -- 14 : �`�[No5
      ,price_ctl_flg       VARCHAR2(1)                                        -- 15 : ���z�\��
      ,emp_no              per_all_people_f.employee_number%TYPE              -- 16 : �S����
      ,creation_date_from  DATE                                               -- 17 : �X�V����FROM
      ,creation_date_to    DATE                                               -- 18 : �X�V����TO
    ) ;
  -- ���׏��f�[�^
  TYPE rec_data_type_dtl IS RECORD
    (
       batch_id            gme_batch_header.batch_id%TYPE                -- ���Y�o�b�`ID
      ,dept_code           xxcmn_locations2_v.location_code%TYPE         -- �����R�[�h
      ,dept_name           xxcmn_locations2_v.description%TYPE           -- ��������
      ,item_location_code  xxcmn_item_locations2_v.segment1%TYPE         -- �ۊǑq�ɃR�[�h
      ,item_location_name  xxcmn_item_locations2_v.description%TYPE      -- �ۊǑq�ɖ�
      ,item_div_type       xxcmn_item_categories4_v.item_class_code%TYPE -- �i�ڋ敪�R�[�h
      ,item_div_value      xxcmn_item_categories4_v.item_class_name%TYPE -- �i�ڋ敪����
      ,entry_no            gme_batch_header.batch_no%TYPE                -- �`�[NO
      ,entry_date          gme_batch_header.actual_cmplt_date%TYPE       -- ���o�ɓ�
      ,pay_reason_code     xxcmn_rcv_pay_mst.new_div_invent%TYPE         -- ���o���R�R�[�h
      ,pay_reason_name     fnd_lookup_values.meaning%TYPE                -- ���o���R����
      ,pay_item_no         xxcmn_item_mst2_v.item_no%TYPE                -- ���o�i�ڃR�[�h
--mod start 1.2
--      ,pay_item_name       xxcmn_item_mst2_v.item_desc1%TYPE             -- ���o�i�ږ���
      ,pay_item_name       xxcmn_item_mst2_v.item_short_name%TYPE        -- ���o�i�ږ���
--mod end 1.2
      ,pay_lot_no          ic_lots_mst.lot_no%TYPE                       -- ���o���b�gNO
      ,pay_quant           NUMBER                                        -- ���o����
      ,pay_unt_price       ic_lots_mst.attribute7%TYPE                   -- ���o�P��
      ,rcv_reason_code     xxcmn_rcv_pay_mst.new_div_invent%TYPE         -- ������R�R�[�h
      ,rcv_reason_name     fnd_lookup_values.meaning%TYPE                -- ������R����
      ,rcv_item_no         xxcmn_item_mst2_v.item_no%TYPE                -- ����i�ڃR�[�h
--mod start 1.2
--      ,rcv_item_name       xxcmn_item_mst2_v.item_desc1%TYPE             -- ����i�ږ���
      ,rcv_item_name       xxcmn_item_mst2_v.item_short_name%TYPE        -- ����i�ږ���
--mod end 1.2
      ,rcv_lot_no          ic_lots_mst.lot_no%TYPE                       -- ������b�gNO
      ,rcv_quant           NUMBER                                        -- �������
      ,rcv_unt_price       ic_lots_mst.attribute7%TYPE                   -- ����P��
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  gr_param                  rec_param_data ;          -- ���̓p�����[�^
--
    gv_sql_date_from VARCHAR2(140) ; -- SQL���F�p�����[�^DATE_FROM��
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  parameter_check_expt     EXCEPTION;     -- �p�����[�^�`�F�b�N��O
--
  /**********************************************************************************
   * Function Name    : funk_item_ctl_chk
   * Description      : �i�ڂ̃p�����[�^�̑��փ`�F�b�N (C1)
   *                    (IN���o�i�ڋ敪)���͗L�F(IN�i��ID)(IN�i�ڋ敪)�̑��֐���
   *                    (IN���o�i�ڋ敪)���͖��F(IN�i��ID)�̒P�̐���
   *                    (OUT)�G���[�FTRUE
   *                    (OUT)����FFALSE
   ***********************************************************************************/
  FUNCTION funk_item_ctl_chk
    (
      iv_item_id   IN NUMBER     -- �i��ID
     ,iv_item_ctl  IN VARCHAR2   -- �i�ڋ敪
    )RETURN BOOLEAN
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'funk_item_ctl_chk' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_str1 VARCHAR2(1) ;
    lv_str2 VARCHAR2(1) ;
    lv_str3 VARCHAR2(1) ;
    ln_work NUMBER;
--
  BEGIN
--
    -- �p�����[�^�F�i�ڃJ�e�S���̓��͗L���`�F�b�N
    IF (iv_item_ctl IS NULL) THEN
      -- �W���J�e�S�����Z�b�g
      lv_str1 := gc_item_ctl_mtl;
      lv_str2 := gc_item_ctl_haif_prd;
      lv_str3 := gc_item_ctl_prd;
    ELSE
      -- �w��J�e�S�����Z�b�g
      lv_str1 := iv_item_ctl;
      lv_str2 := iv_item_ctl;
      lv_str3 := iv_item_ctl;
    END IF;
--
    -- �f�[�^�L���`�F�b�N
    SELECT COUNT(item_id) INTO ln_work
    FROM xxcmn_item_categories4_v
    WHERE item_class_code IN(lv_str1,lv_str2,lv_str3)
    AND item_id = iv_item_id
    AND ROWNUM = 1 ;
--
    -- ���ʔ���:SQL���ʂ��ߒl�𐶐�
    IF (ln_work = 0) THEN
      RETURN TRUE ;
    ELSE 
      RETURN FALSE ;
    END IF ;
--
  END funk_item_ctl_chk ;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : �p�����[�^�`�F�b�N(C-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ov_errbuf     OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- �v���O������
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
    lv_err_code               VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    parameter_dpnd_check_expt     EXCEPTION ;     -- �p�����[�^�`�F�b�N(����)��O
    parameter_unt_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N(�P��)��O
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^�F�i��1�̓��͗L��
    IF (gr_param.item1 IS NOT NULL ) THEN
      -- �i�ڂ̃p�����[�^�̑��փ`�F�b�N
      IF (funk_item_ctl_chk(gr_param.item1,gr_param.out_item_ctl)) THEN
        -- �p�����[�^�F���o�i�ڋ敪�̓��͗L��
        IF (gr_param.out_item_ctl IS NULL) THEN
          -- �P�̗�O
          RAISE parameter_unt_check_expt ;
        ELSE
          -- ���֗�O
          RAISE parameter_dpnd_check_expt ;
        END IF ;
      END IF ;
    END IF ;
    -- �p�����[�^�F�i��2�̓��͗L��
    IF (gr_param.item2 IS NOT NULL ) THEN
      -- �i�ڂ̃p�����[�^�̑��փ`�F�b�N
      IF (funk_item_ctl_chk(gr_param.item2,gr_param.out_item_ctl)) THEN
        -- �p�����[�^�F���o�i�ڋ敪�̓��͗L��
        IF (gr_param.out_item_ctl IS NULL) THEN
          -- �P�̗�O
          RAISE parameter_unt_check_expt ;
        ELSE
          -- ���֗�O
          RAISE parameter_dpnd_check_expt ;
        END IF ;
      END IF ;
    END IF;
    -- �p�����[�^�F�i��3�̓��͗L��
    IF (gr_param.item3 IS NOT NULL ) THEN
      -- �i�ڂ̃p�����[�^�̑��փ`�F�b�N
      IF (funk_item_ctl_chk(gr_param.item3,gr_param.out_item_ctl)) THEN
        -- �p�����[�^�F���o�i�ڋ敪�̓��͗L��
        IF (gr_param.out_item_ctl IS NULL) THEN
          -- �P�̗�O
          RAISE parameter_unt_check_expt ;
        ELSE
          -- ���֗�O
          RAISE parameter_dpnd_check_expt ;
        END IF ;
      END IF ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N(����)��O ***
    WHEN parameter_dpnd_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv,gc_err_code_dpnd_valid ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
    --*** �p�����[�^�`�F�b�N(�P��)��O ***
    WHEN parameter_unt_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv,gc_err_code_unt_valid ) ;
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
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name  IN VARCHAR2,
    iv_value IN VARCHAR2,
    ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_into_xml'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_convert_data VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_prod_pay_data
   * Description      : PROD:���Y���o�f�[�^�擾�v���V�[�W��(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_prod_pay_data
    (
      ot_data_rec   OUT tab_data_type_dtl  -- �擾���R�[�h
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_prod_pay_data'; -- �v���O������
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ���[�J���E�ϐ� ***
    lv_sql_body    VARCHAR2(10000);  -- SQL���F�{��
    lv_work_str    VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�`�[No�i��
    lv_work_str_2  VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�i�ڍi��
    -- �H���}�X�^�F�H���敪
    lv_routing_class          gmd_routings_b.routing_class%TYPE ;
    lv_routing_class_ret      gmd_routings_b.routing_class%TYPE ;
    lv_routing_class_separate gmd_routings_b.routing_class%TYPE ;
--
  BEGIN
--
    -- ------------------------------------------------------------------------------
    -- ��������
    -- ------------------------------------------------------------------------------
--
    -- �H���敪�擾
--
    -- �i�ڐU��
    SELECT grct.routing_class          -- �H���敪
    INTO   lv_routing_class
    FROM   gmd_routing_class_tl grct   -- �H���敪�}�X�^���{��
    WHERE  grct.routing_class_desc = FND_PROFILE.VALUE(gc_routing_class)
    AND    grct.language           = 'JA'
    ;
--
    -- �ԕi����
    SELECT grct.routing_class          -- �H���敪
    INTO   lv_routing_class_ret
    FROM   gmd_routing_class_tl grct   -- �H���敪�}�X�^���{��
    WHERE  grct.routing_class_desc = FND_PROFILE.VALUE(gc_routing_class_ret)
    AND    grct.language           = 'JA'
    ;
--
    -- ��̔����i
    SELECT grct.routing_class          -- �H���敪
    INTO   lv_routing_class_separate
    FROM   gmd_routing_class_tl grct   -- �H���敪�}�X�^���{��
    WHERE  grct.routing_class_desc = FND_PROFILE.VALUE(gc_routing_class_separate)
    AND    grct.language           = 'JA'
    ;
--
    -- ------------------------------------------------------------------------------
    -- ���C��SQL
    -- ------------------------------------------------------------------------------
    -- SQL�{��
    lv_sql_body := lv_sql_body || ' SELECT ' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,xlv.description             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no                AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date       AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS pay_item_no' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS pay_item_name' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
    ---------------------------------------------------------------------------------------
    -- FROM��
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_categories4_v xicv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_batch_header          gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v        xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                   fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    ------------------------------------------------------------
    -- WHERE��
    -- OPM�ۗ��݌Ƀg�����U�N�V�����i��
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = ''' || gc_line_type_pay || '''';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = ''' || gc_doc_type_prod || '''';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = ''' || gc_comp_ind_on   || '''';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
    -- �󕥋敪�A�h�I���}�X�^����
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = ''' || gc_use_div_invent_rep ||'''';
    -- �H��=�ԕi����/��̔����i/�i�ڐU��
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class IN(' ;
    lv_sql_body := lv_sql_body ||  '''' || lv_routing_class          || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || lv_routing_class_ret      || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || lv_routing_class_separate || ''')' ;
    -- ���Y�o�b�`����
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    lv_sql_body := lv_sql_body || ' AND gbh.batch_status           = ' || cv_sc || gc_batch_status_close ||cv_sc ;
    -- OPM�i�ڏ��VIEW����
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- OPM�i�ڃJ�e�S���������VIEW����
    lv_sql_body := lv_sql_body || ' AND ximv.item_id  = xicv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND xicv.item_class_code       IN (' ;
    lv_sql_body := lv_sql_body ||  '''' || gc_item_class_code_1 || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || gc_item_class_code_4 || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || gc_item_class_code_5 || ''')' ;
    -- �W���������VIEW����
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM���b�g�}�X�^����
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
--add end 1.2
    -- �N�C�b�N�R�[�h(�V�敪)����
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ���[�U�}�X�^����
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = gbh.created_by' ;
    -- �]�ƈ��}�X�^����
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
--add end 1.2
    -- ���Ə����VIEW����
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xlv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xlv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM�ۊǏꏊ���VIEW����
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location' ;
    -------------------------------------------------------------------------------
    --�K�{�p�����[�^�i��
    --  1�D�N����_FROM
    --  2�D�N����_TO
--mod start 1.3
--    lv_sql_body := lv_sql_body || ' AND gbh.actual_cmplt_date      BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' AND TRUNC(gbh.actual_cmplt_date) BETWEEN FND_DATE.STRING_TO_DATE(';
--mod end 1.3
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_from,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_to,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    -------------------------------------------------------------------------------
    --  3�D���o�i�ڋ敪
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xicv.item_class_code =' || cv_sc || gr_param.out_item_ctl || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  7�D���R�R�[�h
    IF (gr_param.reason_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrpm.new_div_invent ='
                                      || cv_sc || gr_param.reason_code || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  8�D�ۊǑq�ɃR�[�h
    IF (gr_param.item_location_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id ='
                                      || cv_sc || gr_param.item_location_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  9�D�S������
    IF (gr_param.dept_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND paaf.location_id ='
                                      || cv_sc || gr_param.dept_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    -- �`�[No1
    IF (gr_param.entry_no1 IS NOT NULL) THEN
      lv_work_str := cv_sc || gr_param.entry_no1 || cv_sc ;
    END IF;
    -- �`�[No2
    IF (gr_param.entry_no2 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str || cv_sc || gr_param.entry_no2 || cv_sc ;
    END IF;
    -- �`�[No3
    IF (gr_param.entry_no3 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no3 || cv_sc ;
    END IF;
    -- �`�[No4
    IF (gr_param.entry_no4 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no4 || cv_sc ;
    END IF;
    -- �`�[No5
    IF (gr_param.entry_no5 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no5 || cv_sc ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.batch_no IN('||lv_work_str || ')';
    END IF ;
    -- �p�����[�^�i��(�i��ID)
    -- �i��1
    IF (gr_param.item1 IS NOT NULL) THEN
      lv_work_str_2 := gr_param.item1;
    END IF;
    -- �i��2
    IF (gr_param.item2 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item2 ;
    END IF ;
    -- �i��3
    IF (gr_param.item3 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item3 ;
    END IF ;
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itp.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- �S����
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- �X�V����FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- �X�V����TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY ��
    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec ;
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
  END prc_get_prod_pay_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_prod_rcv_data
   * Description      : PROD:���Y����f�[�^�擾�v���V�[�W��(C2)
   ***********************************************************************************/
--
  PROCEDURE prc_get_prod_rcv_data
    (
      in_batch_id   NUMBER                 -- �o�b�`ID
     ,ot_data_rec   OUT tab_data_type_dtl  -- �擾���R�[�h
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_prod_rcv_data'; -- �v���O������
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ���[�J���E�ϐ� ***
    lv_sql_body    VARCHAR2(10000);  -- SQL���F�{��
    lv_work_str    VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�`�[No�i��
    lv_work_str_2  VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�i�ڍi��
--
  BEGIN
--
    -- SQL�{��
    lv_sql_body := lv_sql_body || ' SELECT ' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS rcv_item_no' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS rcv_item_name' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS rcv_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || ' END                          AS rcv_unt_price' ;
    ---------------------------------------------------------------------------------------
    -- FROM��
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_batch_header          gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    ------------------------------------------------------------
    -- WHERE��
    -- OPM�ۗ��݌Ƀg�����U�N�V�����i��
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = ''' || gc_line_type_rcv || '''';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = ''' || gc_doc_type_prod || '''';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = ''' || gc_comp_ind_on   || '''';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
    -- �󕥋敪�A�h�I���}�X�^����
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = ''' || gc_use_div_invent_rep ||'''';
    -- ���Y�o�b�`����
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    -- OPM�i�ڏ��VIEW����
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- �W���������VIEW����
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM���b�g�}�X�^����
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
--add end 1.2
    -- �N�C�b�N�R�[�h(�V�敪)����
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -------------------------------------------------------------------------------
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id = ' || in_batch_id ;
    -------------------------------------------------------------------------------
    --ORDER BY ��
    lv_sql_body := lv_sql_body || ' ORDER BY ';
    lv_sql_body := lv_sql_body || '  xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec ;
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
  END prc_get_prod_rcv_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_adji_data
   * Description      : ADJI:�݌ɒ���(��)�f�[�^�擾�v���V�[�W��(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_adji_data
    (
      in_line_type  IN NUMBER              -- ���C���^�C�v(��: 1/��:-1)
     ,ot_data_rec   OUT tab_data_type_dtl  -- �擾���R�[�h
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_adji_data'; -- �v���O������
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ���[�J���E�ϐ� ***
    lv_sql_body    VARCHAR2(10000);  -- SQL���F�{��
    lv_work_str    VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�`�[No�i��
    lv_work_str_2  VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�i�ڍi��
--
  BEGIN
--
    -- SQL�{��
    IF(in_line_type = -1) THEN
      lv_sql_body := lv_sql_body || ' SELECT ' ;
      lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
      lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
      lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
      lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
      lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value';
      lv_sql_body := lv_sql_body || ' ,ijm.journal_no              AS entry_no' ;
      lv_sql_body := lv_sql_body || ' ,itc.trans_date              AS entry_date';
      lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS pay_item_no' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS pay_item_name';
--      lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no';
      lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS pay_item_name';
      lv_sql_body := lv_sql_body || ' ,DECODE(ilm.lot_id,0,NULL,ilm.lot_no) AS pay_lot_no';
--mod end 1.2
      lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itc.trans_qty),4) AS pay_quant';
      lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
      lv_sql_body := lv_sql_body || '    ELSE ' ;
      lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
      lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no';
      lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant';
      lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
    ELSE
      lv_sql_body := lv_sql_body || ' SELECT ' ;
      lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
      lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
      lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
      lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
      lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value';
      lv_sql_body := lv_sql_body || ' ,ijm.journal_no              AS entry_no' ;
      lv_sql_body := lv_sql_body || ' ,itc.trans_date              AS entry_date';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_no' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_name';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_lot_no';
      lv_sql_body := lv_sql_body || ' ,0                           AS pay_quant';
      lv_sql_body := lv_sql_body || ' ,0                           AS pay_unt_price' ;
      lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS rcv_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS rcv_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS rcv_item_no' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS rcv_item_name';
--      lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS rcv_lot_no';
      lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS rcv_item_name';
      lv_sql_body := lv_sql_body || ' ,DECODE(ilm.lot_id,0,NULL,ilm.lot_no) AS rcv_lot_no';
--mod end 1.2
      lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itc.trans_qty),4) AS rcv_quant';
      lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
      lv_sql_body := lv_sql_body || '    ELSE ' ;
      lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
      lv_sql_body := lv_sql_body || ' END                          AS rcv_unt_price' ;
    END IF ;
    ---------------------------------------------------------------------------------------
    -- FROM��
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_categories4_v xicv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst6_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,ic_jrnl_mst               ijm' ;
    lv_sql_body := lv_sql_body || ' ,ic_adjs_jnl               iaj' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_cmp               itc' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v        xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                   fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    ------------------------------------------------------------
    -- WHERE��
    -- OPM�W���[�i���݌ɒ����W���[�i������
    lv_sql_body := lv_sql_body || ' WHERE itc.doc_id               = iaj.doc_id';
    lv_sql_body := lv_sql_body || ' AND itc.doc_line               = iaj.doc_line';
    -- OPM�W���[�i���}�X�^����
    lv_sql_body := lv_sql_body || ' AND iaj.journal_id             = ijm.journal_id';
    -- �󕥋敪���VIEW���Y����
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type              = itc.doc_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.reason_code           = itc.reason_code';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = ''' || gc_use_div_invent_rep || '''';
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div           = TO_CHAR( SIGN( itc.trans_qty ) )';
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div           = :line_type';
    -- OPM�i�ڏ��VIEW����
    lv_sql_body := lv_sql_body || ' AND itc.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- OPM�i�ڃJ�e�S���������VIEW����
    lv_sql_body := lv_sql_body || ' AND ximv.item_id  = xicv.item_id' ;
    -- �W���������VIEW����
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itc.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM���b�g�}�X�^����
    lv_sql_body := lv_sql_body || ' AND itc.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itc.item_id                = ilm.item_id' ;
--add end 1.2
    -- �N�C�b�N�R�[�h(�V�敪)����
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ���[�U�}�X�^����
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = itc.created_by' ;
    -- �]�ƈ��}�X�^����
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
--add end 1.2
    -- ���Ə����VIEW����
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xlv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xlv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM�ۊǏꏊ���VIEW����
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itc.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itc.location' ;
    -------------------------------------------------------------------------------
    --�K�{�p�����[�^�i��
    --  1�D�N����_FROM
    --  2�D�N����_TO
    lv_sql_body := lv_sql_body || ' AND itc.trans_date      BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_from,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_to,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    --  3�D���o�i�ڋ敪
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xicv.item_class_code = ' || cv_sc || gr_param.out_item_ctl || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  7�D���R�R�[�h
    IF (gr_param.reason_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrpm.new_div_invent = '
                                      || cv_sc || gr_param.reason_code || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  8�D�ۊǑq�ɃR�[�h
    IF (gr_param.item_location_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id = '
                                      || cv_sc || gr_param.item_location_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  9�D�S������
    IF (gr_param.dept_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND paaf.location_id = '
                                      || cv_sc || gr_param.dept_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    -- �`�[No1
    IF (gr_param.entry_no1 IS NOT NULL) THEN
      lv_work_str := cv_sc || gr_param.entry_no1 || cv_sc ;
    END IF;
    -- �`�[No2
    IF (gr_param.entry_no2 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str || cv_sc || gr_param.entry_no2 || cv_sc ;
    END IF;
    -- �`�[No3
    IF (gr_param.entry_no3 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no3 || cv_sc ;
    END IF;
    -- �`�[No4
    IF (gr_param.entry_no4 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no4 || cv_sc ;
    END IF;
    -- �`�[No5
    IF (gr_param.entry_no5 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no5 || cv_sc ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND ijm.journal_no IN('||lv_work_str || ')';
    END IF ;
    -- �p�����[�^�i��(�i��ID)
    -- �i��1
    IF (gr_param.item1 IS NOT NULL) THEN
      lv_work_str_2 := gr_param.item1;
    END IF;
    -- �i��2
    IF (gr_param.item2 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item2 ;
    END IF;
    -- �i��3
    IF (gr_param.item3 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item3 ;
    END IF;
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itc.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- �S����
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- �X�V����FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itc.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- �X�V����TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itc.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY ��
    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,ijm.journal_no' ;
    lv_sql_body := lv_sql_body || ' ,itc.trans_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING in_line_type ;
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
  END prc_get_adji_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_omso_porc_data
   * Description      : OSMO:���{�o��/�p�� PORC�RMA:���{�o�Ɏ��/�p�����(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_omso_porc_data
    (
      iv_doc_type   IN VARCHAR2            -- �����^�C�v
     ,ot_data_rec   OUT tab_data_type_dtl  -- �擾���R�[�h
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_omso_porc_data'; -- �v���O������
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ���[�J���E�ϐ� ***
    lv_sql_body    VARCHAR2(10000);  -- SQL���F�{��
    lv_work_str    VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�`�[No�i��
    lv_work_str_2  VARCHAR2(100) ;   -- ��Ɨp�ϐ�:�i�ڍi��
  BEGIN
--
    -- SQL�{��
    lv_sql_body := lv_sql_body || ' SELECT ' ;
    lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,xoha.request_no             AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,xoha.shipped_date           AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS pay_item_no' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS pay_item_name' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
    IF (iv_doc_type = gc_doc_type_porc) THEN
      lv_sql_body := lv_sql_body || ',ROUND(itp.trans_qty*-1,4)    AS pay_quant' ;
    ELSE
      lv_sql_body := lv_sql_body || ',ABS(ROUND(itp.trans_qty,4))  AS pay_quant' ;
    END IF ;
    lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || ' END                          AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name';
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no';
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant';
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
    ---------------------------------------------------------------------------------------
    -- FROM��
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_categories4_v xicv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_rcv_pay_mst        xrpm' ;
    lv_sql_body := lv_sql_body || ' ,oe_transaction_types_all otta' ;
    lv_sql_body := lv_sql_body || ' ,oe_order_headers_all     ooha' ;
    lv_sql_body := lv_sql_body || ' ,xxwsh_order_headers_all  xoha' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v        xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                   fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    IF (iv_doc_type = gc_doc_type_omso) THEN
      lv_sql_body := lv_sql_body || ',wsh_delivery_details     wdd' ;
    ELSE
      lv_sql_body := lv_sql_body || ',rcv_shipment_lines       rsl' ;
    END IF ;
    ---------------------------------------------------------------------------------------
    -- WHERE��
    -- OPM�ۗ��݌Ƀg�����U�N�V�����i��
    lv_sql_body := lv_sql_body || ' WHERE itp.completed_ind             = ''' || gc_comp_ind_on   || '''';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id                  IS NULL' ;
    -- �󕥋敪�A�h�I���}�X�^����
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type                   = itp.doc_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11';
    lv_sql_body := lv_sql_body || ' AND xrpm.stock_adjustment_div       = otta.attribute4';
    lv_sql_body := lv_sql_body || ' AND xrpm.stock_adjustment_div       = '   ||  gc_stock_adjst_div_sa ;
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep         = ''' || gc_use_div_invent_rep  || '''' ;
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div                = '   || gc_line_type_pay  ;
    -- �󒍃w�b�_(�A�h�I��)����
    lv_sql_body := lv_sql_body || ' AND xoha.header_id                  = ooha.header_id' ;
    -- �󒍃^�C�v����
    lv_sql_body := lv_sql_body || ' AND otta.transaction_type_id        = xoha.order_type_id' ;
    -- OPM�i�ڏ��VIEW����
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- OPM�i�ڃJ�e�S���������VIEW����
    lv_sql_body := lv_sql_body || ' AND ximv.item_id  = xicv.item_id' ;
    -- �W���������VIEW����
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM���b�g�}�X�^����
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
--add end 1.2
    -- �N�C�b�N�R�[�h(�V�敪)����
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ���[�U�}�X�^����
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = xoha.created_by' ;
    -- �]�ƈ��}�X�^����
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
--add end 1.2
    -- ���Ə����VIEW����
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xlv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xlv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM�ۊǏꏊ���VIEW����
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location'  ;
--
    -- OMSO/PORC�敪�ɂ�錋����������
    IF (iv_doc_type = gc_doc_type_omso) THEN
      -- �o�ה������׌���
      lv_sql_body := lv_sql_body || ' AND itp.line_id               = wdd.source_line_id' ;
      -- �󒍃w�b�_����
      lv_sql_body := lv_sql_body || ' AND ooha.org_id               = wdd.org_id' ;
      lv_sql_body := lv_sql_body || ' AND ooha.header_id            = wdd.source_header_id' ;
      -- �󕥋敪�A�h�I���}�X�^����
      lv_sql_body := lv_sql_body || ' AND xrpm.doc_type             = ''' || gc_doc_type_omso || '''' ;
    ELSE
      -- ������׌���
      lv_sql_body := lv_sql_body || ' AND rsl.shipment_header_id    = itp.doc_id' ;
      lv_sql_body := lv_sql_body || ' AND rsl.line_num              = itp.doc_line';
      lv_sql_body := lv_sql_body || ' AND rsl.oe_order_header_id    = ooha.header_id' ;
      -- �󕥋敪�A�h�I���}�X�^����
      lv_sql_body := lv_sql_body || ' AND xrpm.doc_type             = ''' || gc_doc_type_porc        || '''' ;
      lv_sql_body := lv_sql_body || ' AND xrpm.source_document_code = ''' || gc_source_doc_type_rma  || '''' ;
    END IF ;
--
    -------------------------------------------------------------------------------
    --�K�{�p�����[�^�i��
    --  1�D�N����_FROM
    --  2�D�N����_TO
    lv_sql_body := lv_sql_body || ' AND xoha.shipped_date      BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_from,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    lv_sql_body := lv_sql_body || '                            AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_to,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    -------------------------------------------------------------------------------
    --  3�D���o�i�ڋ敪
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xicv.item_class_code =' || cv_sc || gr_param.out_item_ctl || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  7�D���R�R�[�h
    IF (gr_param.reason_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrpm.new_div_invent = '
                                      || cv_sc || gr_param.reason_code || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  8�D�ۊǑq�ɃR�[�h
    IF (gr_param.item_location_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id ='
                                      || cv_sc || gr_param.item_location_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  9�D�S������
    IF (gr_param.dept_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND paaf.location_id = '
                                      || cv_sc || gr_param.dept_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    -- �`�[No1
    IF (gr_param.entry_no1 IS NOT NULL) THEN
      lv_work_str := cv_sc || gr_param.entry_no1 || cv_sc ;
    END IF;
    -- �`�[No2
    IF (gr_param.entry_no2 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str || cv_sc || gr_param.entry_no2 || cv_sc ;
    END IF;
    -- �`�[No3
    IF (gr_param.entry_no3 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no3 || cv_sc ;
    END IF;
    -- �`�[No4
    IF (gr_param.entry_no4 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no4 || cv_sc ;
    END IF;
    -- �`�[No5
    IF (gr_param.entry_no5 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no5 || cv_sc ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xoha.request_no IN('||lv_work_str || ')';
    END IF ;
    -- �p�����[�^�i��(�i��ID)
    -- �i��1
    IF (gr_param.item1 IS NOT NULL) THEN
      lv_work_str_2 := gr_param.item1;
    END IF;
    -- �i��2
    IF (gr_param.item2 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item2 ;
    END IF;
    -- �i��3
    IF (gr_param.item3 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item3 ;
    END IF;
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND ximv.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- �S����
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- �X�V����FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xoha.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- �X�V����TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xoha.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY ��
    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,xoha.request_no' ;
    lv_sql_body := lv_sql_body || ' ,xoha.shipped_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec ;
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
  END prc_get_omso_porc_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_data_to_tmp_table
   * Description      : �f�[�^���H�E���ԃe�[�u���X�V�v���V�[�W��(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_data_to_tmp_table
    (
      ov_errbuf     OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data_to_tmp_table'; -- �v���O������
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
    -- *** ���[�J���E�ϐ� ***
    ln_batch_id       NUMBER  DEFAULT 0 ;
    lt_prod_all_data  tab_data_type_dtl ;
    ln_prod_cnt       NUMBER  DEFAULT 1 ;
    lt_prod_pay_data  tab_data_type_dtl ;
    lt_prod_rcv_data  tab_data_type_dtl ;
    ln_rcv_cnt        NUMBER  DEFAULT 1 ;
    lt_general_data   tab_data_type_dtl ;
--
  BEGIN
--
    -- ==========================================================
    -- ��������
    -- ==========================================================
    -- SQL���ʕ����񐶐�:�p�����[�^DATE_FROM�����`
    gv_sql_date_from :=  'FND_DATE.STRING_TO_DATE(' ;
    gv_sql_date_from :=  gv_sql_date_from || '''' || TO_CHAR(gr_param.date_from,gc_date_mask) ||''',' ;
    gv_sql_date_from :=  gv_sql_date_from || '''' || gc_date_mask ||''')';
    -- ==========================================================
    -- ���Y(PROD)�f�[�^�擾�E�i�[����
    -- ==========================================================
    -- ���o�f�[�^���o
    prc_get_prod_pay_data
     (
      ot_data_rec  => lt_prod_pay_data
     ,ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    ) ;
--
      <<lt_prod_pay_data_LOOP>>
      FOR i IN 1..lt_prod_pay_data.count LOOP
--
        -- ���񃌃R�[�h�^���f�[�^�u���C�N
        IF ( ( i =1 )
          OR (lt_prod_pay_data(i).batch_id <> ln_batch_id )) THEN
--
          -- �󁄕����̎󍷕��o��
          <<RCV_BREAK_LOOP>>
          WHILE(lt_prod_rcv_data.EXISTS(ln_rcv_cnt)) LOOP
--
            lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i-1).batch_id ;
            lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i-1).dept_code ;
            lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i-1).dept_name,1,20);
            lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i-1).item_location_code ;
            lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i-1).item_location_name ;
            lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i-1).item_div_type ;
            lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i-1).item_div_value ;
            lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i-1).entry_no ;
            lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i-1).entry_date ;
            lt_prod_all_data(ln_prod_cnt). pay_reason_code    := lt_prod_pay_data(i-1).pay_reason_code ;
            lt_prod_all_data(ln_prod_cnt). pay_reason_name    := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
            lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
            lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
            lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
--
            -- �J�E���^�C���N�������g
            ln_prod_cnt := ln_prod_cnt + 1 ;
            ln_rcv_cnt  := ln_rcv_cnt  + 1 ;
--
          END LOOP RCV_BREAK_LOOP ;
--
          -- ��f�[�^�擾
          prc_get_prod_rcv_data
          (
           in_batch_id  => lt_prod_pay_data(i).batch_id
          ,ot_data_rec  => lt_prod_rcv_data
          ,ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
          ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
          ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
         ) ;
          -- ��J�E���^������
          ln_rcv_cnt := 1 ;
          -- ���u���C�N�L�[�Z�b�g
          ln_batch_id := lt_prod_pay_data(i).batch_id ;
--
      END IF;
--
      -- �󑶍݃`�F�b�N
      -- ��L�F�󕥏o�́^�󖳁F���o��
      IF (lt_prod_rcv_data.EXISTS(ln_rcv_cnt)) THEN
--
        lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i).batch_id ;
        lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i).dept_code ;
        lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i).dept_name,1,20);
        lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i).item_location_code ;
        lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i).item_location_name ;
        lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i).item_div_type ;
        lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i).item_div_value ;
        lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i).entry_no ;
        lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i).entry_date ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_code    := lt_prod_pay_data(i).pay_reason_code ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_name    := lt_prod_pay_data(i).pay_reason_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
--
        -- �J�E���^�C���N�������g
        ln_prod_cnt := ln_prod_cnt + 1 ;
        ln_rcv_cnt  := ln_rcv_cnt  + 1 ;
--
      ELSE
--
        lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i).batch_id;
        lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i).dept_code ;
        lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i).dept_name,1,20);
        lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i).item_location_code ;
        lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i).item_location_name ;
        lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i).item_div_type ;
        lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i).item_div_value ;
        lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i).entry_no ;
        lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i).entry_date ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_code    := lt_prod_pay_data(i).pay_reason_code ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_name    := lt_prod_pay_data(i).pay_reason_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := 0 ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := 0 ;
--
        -- �J�E���^�C���N�������g
        ln_prod_cnt := ln_prod_cnt + 1 ;
--
      END IF ;
--
      -- ���t�F�b�`�F�ŏI���R�[�h�� �󁄕����̎󍷕��o��
      IF NOT(lt_prod_pay_data.EXISTS(i+1)) THEN
--
        <<RCV_BREAK_LOOP>>
        WHILE(lt_prod_rcv_data.EXISTS(ln_rcv_cnt)) LOOP
--
          lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i).batch_id ;
          lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i).dept_code ;
          lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i).dept_name,1,20);
          lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i).item_location_code ;
          lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i).item_location_name ;
          lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i).item_div_type ;
          lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i).item_div_value ;
          lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i).entry_no ;
          lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i).entry_date ;NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_reason_code    := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_reason_name    := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
          lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
          lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
          lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
--
          -- �J�E���^�C���N�������g
          ln_prod_cnt := ln_prod_cnt + 1 ;
          ln_rcv_cnt  := ln_rcv_cnt  + 1 ;
--
        END LOOP RCV_BREAK_LOOP ;
--
      END IF;
--
    END LOOP lt_prod_pay_data_LOOP ;
--
    FORALL i in 1 .. lt_prod_all_data.COUNT 
      INSERT INTO XXINV_550C_TMP VALUES lt_prod_all_data(i) ;
--
    -- =========================================================
    -- �݌ɒ���(ADJI)�f�[�^�擾�E�i�[����
    -- =========================================================
--
    -- ---------------------------------------------------------
    -- ���o
    -- ---------------------------------------------------------
    prc_get_adji_data
    (
       in_line_type => gc_line_type_rcv  -- ���C���^�C�v(��: 1/��:-1)
      ,ot_data_rec  => lt_general_data   -- �擾���R�[�h
      ,ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
    ;
--
      -- �݌ɒ���(ADJI)�F��
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
--
    -- XXINV55C���ԃe�[�u���^�ϐ�������
    lt_general_data.DELETE ;
--
    prc_get_adji_data
    (
       in_line_type => gc_line_type_pay   -- ���C���^�C�v(��: 1/��:-1)
      ,ot_data_rec  => lt_general_data    -- �擾���R�[�h
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
    ;
--
      -- �݌ɒ���(ADJI)�F��
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
--
    -- XXINV55C���ԃe�[�u���^�ϐ�������
    lt_general_data.DELETE ;
--
    -- =========================================================
    -- ���{�o��(OMSO) �f�[�^�擾�E�i�[����
    -- =========================================================
    prc_get_omso_porc_data
    (
       iv_doc_type  => gc_doc_type_omso  -- �����^�C�v�FOMSO(���{�o��)
      ,ot_data_rec  => lt_general_data   -- �擾���R�[�h
      ,ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
    ;
--
      -- ���{�o��(OMSO)�F��
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
--
    -- XXINV55C���ԃe�[�u���^�ϐ�������
    lt_general_data.DELETE ;
--
    -- =========================================================
    -- �p��(�o��)PROC�RMA �f�[�^�擾�E�i�[����
    -- =========================================================
    prc_get_omso_porc_data
    (
       iv_doc_type  => gc_doc_type_porc  -- �����^�C�v�FOMSO(���{�o��)
      ,ot_data_rec  => lt_general_data   -- �擾���R�[�h
      ,ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
    ;
--
      -- �p��(�o��)PROC�RMA �F��
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
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
  END prc_get_data_to_tmp_table ;
--
--
   /**********************************************************************************
   * Procedure Name   : prc_get_data_from_tmp_table
   * Description      :�f�[�^�擾(�ŏI�o�̓f�[�^)�v���V�[�W��(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_data_from_tmp_table
    (
      ot_out_data   OUT tab_data_type_dtl  -- �擾���R�[�h
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data_from_tmp_table'; -- �v���O������
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
    SELECT
     batch_id            -- �o�b�`ID
    ,dept_code           -- �����R�[�h
    ,dept_name           -- ��������
    ,item_location_code  -- �ۊǑq�ɃR�[�h
    ,item_location_name  -- �ۊǑq�ɖ�
    ,item_div_type       -- �i�ڋ敪�R�[�h
    ,item_div_value      -- �i�ڋ敪����
    ,entry_no            -- �`�[NO
    ,entry_date          -- ���o�ɓ�
    ,pay_reason_code     -- ���o���R�R�[�h
    ,pay_reason_name     -- ���o���R����
    ,pay_item_no         -- ���o�i�ڃR�[�h
    ,pay_item_name       -- ���o�i�ږ���
    ,pay_lot_no          -- ���o���b�gNO
    ,pay_quant           -- ���o����
    ,pay_unt_price       -- ���o�P��
    ,rcv_reason_code     -- ������R�R�[�h
    ,rcv_reason_name     -- ������R����
    ,rcv_item_no         -- ����i�ڃR�[�h
    ,rcv_item_name       -- ����i�ږ���
    ,rcv_lot_no          -- ������b�gNO
    ,rcv_quant           -- �������
    ,rcv_unt_price       -- ����P��
    BULK COLLECT INTO ot_out_data
    FROM
    XXINV_550C_TMP
    ORDER BY
     dept_code
    ,item_location_code
    ,item_div_type
--add start 1.4
    ,CASE
       WHEN rcv_item_no IS NOT NULL AND pay_item_no IS NULL
         THEN 1
         ELSE 2
     END
--add end 1.4
--mod start 1.3
    ,pay_reason_code
    ,entry_no
    ,entry_date
--    ,pay_reason_code
--mod end 1.3
    ,pay_item_no
    ,pay_lot_no
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
  END prc_get_data_from_tmp_table ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(C-3/C-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      it_out_data       IN  tab_data_type_dtl       -- 01.�擾���R�[�h
     ,ov_errbuf         OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W
     ,ov_retcode        OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg         OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E��O���� ***
    dtldata_notfound_expt      EXCEPTION ;     -- �Ώۃf�[�^0����O
    -- *** ���[�J���ϐ� ***
    ln_exec_user_id NUMBER ;
  BEGIN
--
    -- ----------------------------------------------------
    -- �J�n�^�O
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    -- �f�[�^���擾�̏ꍇ
    IF (it_out_data.count = 0) THEN
      ------------------------------
      -- �f�[�^�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'datainfo' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- ����L�f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dept_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �����f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �ۊǑq��L�f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_location_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �ۊǑq�ɂf�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �i�ڋ敪L�f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �i�ڋ敪�f�J�n�^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
       -- �f�[�^�Ȃ����b�Z�[�W
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'msg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                 ,gc_err_code_data_0 ) ;
      ------------------------------
      -- �i�ڋ敪�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �i�ڋ敪L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �ۊǑq�ɂf�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �ۊǑq��L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_location_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �����f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- ����L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �f�[�^�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/datainfo' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
      RAISE dtldata_notfound_expt ;
--
    ELSE
      ln_exec_user_id := FND_GLOBAL.USER_ID;
      <<param_data_loop>>
      FOR i IN 1..it_out_data.count LOOP
        -- ��������
        IF ( i = 1 ) THEN
          ------------------------------
          -- ���[�U�f�[�^�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- ���[ID
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id;
          -- �o�͓���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(SYSDATE,gc_date_mask);
          -- �S��(������)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value 
                := xxcmn_common_pkg.get_user_dept(ln_exec_user_id);
          -- �S��(����)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value 
                := xxcmn_common_pkg.get_user_name(ln_exec_user_id);
          ------------------------------
          -- ���[�U�f�[�^�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �p�����[�^�f�[�^�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- ����(FROM)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'date_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_from,gc_date_mask_jp);
          -- ����(TO)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'date_to' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_to,gc_date_mask_jp);
          -- ���z�\���t���O
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'price_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := gr_param.price_ctl_flg ;
          ------------------------------
          -- �p�����[�^�f�[�^�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �f�[�^�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'datainfo' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dept_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �����f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �S�������R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_code;
          -- �S��������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_name;
          ------------------------------
          -- �ۊǑq��L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_location_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �ۊǑq�ɂf�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �ۊǑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_code ;
          -- �ۊǑq�ɖ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_name ;
          ------------------------------
          -- �i�ڋ敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- ���RL�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- �J�����g���R�[�h�ƑO���R�[�h�̎��R���s��v
--mod start 1.3
--        ELSIF (it_out_data(i-1).pay_reason_code <> it_out_data(i).pay_reason_code)
        ELSIF (NVL(it_out_data(i-1).pay_reason_code,'dummy') <> NVL(it_out_data(i).pay_reason_code,'dummy'))
--mod end 1.3
        AND   (it_out_data(i-1).item_div_type      = it_out_data(i).item_div_type)
        AND   (it_out_data(i-1).item_location_code = it_out_data(i).item_location_code)
        AND   (it_out_data(i-1).dept_code          = it_out_data(i).dept_code) THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- �J�����g���R�[�h�ƑO���R�[�h�̕i�ڋ敪���s��v
        ELSIF (it_out_data(i-1).item_div_type     <> it_out_data(i).item_div_type)
        AND   (it_out_data(i-1).item_location_code = it_out_data(i).item_location_code)
        AND   (it_out_data(i-1).dept_code          = it_out_data(i).dept_code) THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���RL�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- ���RL�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- �J�����g���R�[�h�ƑO���R�[�h�̕ۊǑq�ɂ��s��v
        ELSIF (it_out_data(i-1).item_location_code <> it_out_data(i).item_location_code)
        AND   (it_out_data(i-1).dept_code           = it_out_data(i).dept_code)THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���RL�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �ۊǑq�ɂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �ۊǑq�ɂf�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �ۊǑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_code;
          -- �ۊǑq�ɖ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_name;
          ------------------------------
          -- �i�ڋ敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- ���RL�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- �J�����g���R�[�h�ƑO���R�[�h�̕������s��v
        ELSIF (it_out_data(i-1).dept_code <> it_out_data(i).dept_code) THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���RL�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �ۊǑq�ɂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �ۊǑq��L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_location_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �����f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �S�������R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_code;
          -- �S��������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_name;
          ------------------------------
          -- �ۊǑq��L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_location_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �ۊǑq�ɂf�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �ۊǑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_code;
          -- �ۊǑq�ɖ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_name;
          ------------------------------
          -- �i�ڋ敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- ���RL�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���R�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
--
        ------------------------------
        -- ���ׂf�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
        -- �`�[No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'entry_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).entry_no;
        -- ���o�ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'entry_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_out_data(i).entry_date,gc_date_mask_s);
--
        IF (it_out_data(i).pay_reason_code IS NOT NULL)
        AND(it_out_data(i).pay_reason_name IS NOT NULL) THEN
          -- ���o���R�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_reason_code;
          -- ���o���R����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_reason_name;
        ELSE
          -- ���o���R�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          -- ���o���R����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        END IF ;
--
        -- ���o�i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_item_no;
        -- ���o�i�ږ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_item_name;
        -- ���o���b�gNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_lot_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_lot_no;
        -- ���o����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_quant;
        -- ���o�P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_unt_price;
        -- ���o���z
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value 
              := ROUND( it_out_data(i).pay_unt_price * it_out_data(i).pay_quant ) ;
        -- ������R�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_reason_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_reason_code;
        -- ������R����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_reason_value' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_reason_name;
        -- ����i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_item_no;
        -- ����i�ږ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_item_name;
        -- ������b�gNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_lot_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_lot_no;
        -- �������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_quant;
        -- ����P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_unt_price;
        -- ������z
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value 
              := ROUND( it_out_data(i).rcv_unt_price * it_out_data(i).rcv_quant );
--
        ------------------------------
        -- ���ׂf�I���^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
      END LOOP param_data_loop ;
    END IF ;
--
    --�I������
    ------------------------------
    -- ����L�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- ���R�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- ���RL�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �i�ڋ敪�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �i�ڋ敪L�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �ۊǑq�ɂf�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �ۊǑq��L�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_location_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �����f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- ����L�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- �f�[�^�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/datainfo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    -- ----------------------------------------------------
    -- �I���^�O
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
  EXCEPTION
--
    -- *** �Ώۃf�[�^0����O�n���h�� ***
    WHEN dtldata_notfound_expt THEN
      ov_retcode := gv_status_warn ;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_date_from             IN  VARCHAR2     -- 01 : �N����_FROM
    ,iv_date_to               IN  VARCHAR2     -- 02 : �N����_TO
    ,iv_out_item_ctl          IN  VARCHAR2     -- 03 : ���o�i�ڋ敪
    ,iv_item1                 IN  VARCHAR2     -- 04 : �i��ID1
    ,iv_item2                 IN  VARCHAR2     -- 05 : �i��ID2
    ,iv_item3                 IN  VARCHAR2     -- 06 : �i��ID3
    ,iv_reason_code           IN  VARCHAR2     -- 07 : ���R�R�[�h
    ,iv_item_location_id      IN  VARCHAR2     -- 08 : �ۊǑq��ID
    ,iv_dept_id               IN  VARCHAR2     -- 09 : �S������ID
    ,iv_entry_no1             IN  VARCHAR2     -- 10 : �`�[No1
    ,iv_entry_no2             IN  VARCHAR2     -- 11 : �`�[No2
    ,iv_entry_no3             IN  VARCHAR2     -- 12 : �`�[No3
    ,iv_entry_no4             IN  VARCHAR2     -- 13 : �`�[No4
    ,iv_entry_no5             IN  VARCHAR2     -- 14 : �`�[No5
    ,iv_price_ctl_flg         IN  VARCHAR2     -- 15 : ���z�\��
    ,iv_emp_no                IN  VARCHAR2     -- 16 : �S����
    ,iv_creation_date_from    IN  VARCHAR2     -- 17 : �X�V����FROM
    ,iv_creation_date_to      IN  VARCHAR2     -- 18 : �X�V����TO
    ,ov_errbuf                OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode               OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg                OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
--
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
    lv_xml_string    VARCHAR2(32000);
--
    -- *** ���[�J���ϐ� ***
    lt_out_data      tab_data_type_dtl ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���̓p�����[�^�i�[
    -- ===============================================
    gr_param.date_from
      := FND_DATE.CANONICAL_TO_DATE(iv_date_from) ;                     -- 01 : �N����_FROM
    gr_param.date_to
      := FND_DATE.CANONICAL_TO_DATE(iv_date_to) ;                       -- 02 : �N����_TO
    gr_param.out_item_ctl        := iv_out_item_ctl ;                   -- 03 : ���o�i�ڋ敪
    gr_param.item1               := TO_NUMBER(iv_item1) ;               -- 04 : �i��ID1
    gr_param.item2               := TO_NUMBER(iv_item2) ;               -- 05 : �i��ID2
    gr_param.item3               := TO_NUMBER(iv_item3) ;               -- 06 : �i��ID3
    gr_param.reason_code         := iv_reason_code ;                    -- 07 : ���R�R�[�h
    gr_param.item_location_id    := TO_NUMBER(iv_item_location_id) ;    -- 08 : �ۊǑq�ɃR�[�h
    gr_param.dept_id             := TO_NUMBER(iv_dept_id) ;             -- 09 : �S������
    gr_param.entry_no1           := iv_entry_no1 ;                      -- 10 : �`�[No1
    gr_param.entry_no2           := iv_entry_no2 ;                      -- 11 : �`�[No2
    gr_param.entry_no3           := iv_entry_no3 ;                      -- 12 : �`�[No3
    gr_param.entry_no4           := iv_entry_no4 ;                      -- 13 : �`�[No4
    gr_param.entry_no5           := iv_entry_no5 ;                      -- 14 : �`�[No5
    gr_param.price_ctl_flg       := iv_price_ctl_flg ;                  -- 15 : ���z�\��
    gr_param.emp_no              := iv_emp_no ;                         -- 16 : �S����
    gr_param.creation_date_from
      := FND_DATE.CANONICAL_TO_DATE(iv_creation_date_from) ;            -- 17 : �X�V����FROM
    gr_param.creation_date_to
      := FND_DATE.CANONICAL_TO_DATE(iv_creation_date_to) ;              -- 18 : �X�V����TO
    -- ===============================================
    -- ���̓p�����[�^�`�F�b�N(C-1)
    -- ===============================================
    prc_check_param_info
    (
      ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- �f�[�^���o(C-2)
    -- ===============================================
    -- ���o�f�[�^�𒆊ԃe�[�u���֊i�[
    prc_get_data_to_tmp_table
    (
      ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ���ԃe�[�u�����f�[�^�擾
    prc_get_data_from_tmp_table
    (
      ot_out_data   => lt_out_data        -- �擾���R�[�h�Q
     ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- �w�l�k�f�[�^�쐬(C-3/C-4)
    -- ===============================================
    prc_create_xml_data
    (
      it_out_data  => lt_out_data  -- 01.�o�͑Ώۃ��R�[�h�Q
     ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    --XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := convert_into_xml
                       (
                           iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                          ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                          ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_loop ;
--
    -- ���ԃe�[�u���o�^�f�[�^�̔p������
    ROLLBACK;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg  ;
    ov_errbuf  := lv_errbuf  ;
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
      errbuf                  OUT  VARCHAR2     -- �G���[���b�Z�[�W
     ,retcode                 OUT  VARCHAR2     -- �G���[�R�[�h
     ,iv_date_from            IN   VARCHAR2     -- 01 : �N����_FROM
     ,iv_date_to              IN   VARCHAR2     -- 02 : �N����_TO
     ,iv_out_item_ctl         IN   VARCHAR2     -- 03 : ���o�i�ڋ敪
     ,iv_item1                IN   VARCHAR2     -- 04 : �i��ID1
     ,iv_item2                IN   VARCHAR2     -- 05 : �i��ID2
     ,iv_item3                IN   VARCHAR2     -- 06 : �i��ID3
     ,iv_reason_code          IN   VARCHAR2     -- 07 : ���R�R�[�h
     ,iv_item_location_id     IN   VARCHAR2     -- 08 : �ۊǑq��ID
     ,iv_dept_id              IN   VARCHAR2     -- 09 : �S������ID
     ,iv_entry_no1            IN   VARCHAR2     -- 10 : �`�[No1
     ,iv_entry_no2            IN   VARCHAR2     -- 11 : �`�[No2
     ,iv_entry_no3            IN   VARCHAR2     -- 12 : �`�[No3
     ,iv_entry_no4            IN   VARCHAR2     -- 13 : �`�[No4
     ,iv_entry_no5            IN   VARCHAR2     -- 14 : �`�[No5
     ,iv_price_ctl_flg        IN   VARCHAR2     -- 15 : ���z�\��
     ,iv_emp_no               IN   VARCHAR2     -- 16 : �S����
     ,iv_creation_date_from   IN   VARCHAR2     -- 17 : �X�V����FROM
     ,iv_creation_date_to     IN   VARCHAR2     -- 18 : �X�V����TO
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
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_date_from           -- 01 : �N����_FROM
      ,iv_date_to             -- 02 : �N����_TO
      ,iv_out_item_ctl        -- 03 : ���o�i�ڋ敪
      ,iv_item1               -- 04 : �i��ID1
      ,iv_item2               -- 05 : �i��ID2
      ,iv_item3               -- 06 : �i��ID3
      ,iv_reason_code         -- 07 : ���R�R�[�h	
      ,iv_item_location_id    -- 08 : �ۊǑq��ID
      ,iv_dept_id             -- 09 : �S������ID
      ,iv_entry_no1           -- 10 : �`�[No1
      ,iv_entry_no2           -- 11 : �`�[No2
      ,iv_entry_no3           -- 12 : �`�[No3
      ,iv_entry_no4           -- 13 : �`�[No4
      ,iv_entry_no5           -- 14 : �`�[No5
      ,iv_price_ctl_flg       -- 15 : ���z�\��
      ,iv_emp_no              -- 16 : �S����
      ,iv_creation_date_from  -- 17 : �X�V����FROM
      ,iv_creation_date_to    -- 18 : �X�V����TO
      ,lv_errbuf              -- �G���[�E���b�Z�[�W
      ,lv_retcode             -- ���^�[���E�R�[�h
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
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
END XXINV550003C;
/
