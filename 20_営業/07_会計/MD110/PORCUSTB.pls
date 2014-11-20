/* $Header: PORCUSTB.pls 115.19.11510.5 2005/12/02 18:42:02 sonmukhe ship $ */
--   +==================================================================+
--   |               Copyright (c) 1998 Oracle Corporation 	     |
--   |                  Redwood Shores, California, USA 		     |
--   |                       All rights reserved.  		     |
--   +==================================================================+

--     File:    PORCUSTS.pls
--     Package: POR_CUSTOM_PKG
--     Description:
--       This package contains procedures that allows customer to add in their
--       own business logic for the Requisition process.
--
--     Change History:
--     Mary Chu         Dec 08, 1998  Created

REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE 

SET VERIFY OFF
  WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
  WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE or REPLACE PACKAGE BODY por_custom_pkg AS 
/* $Header: PORCUSTB.pls 115.19.11510.5 2005/12/02 18:42:02 sonmukhe ship $ */

-- Customize this procedure to add custom defaulting logic for all the 
-- attributes on a requisition header. 
-- This is called when a new requisition gets created.
-- The attribute id's are passed as IN OUT NOCOPY parameters to this procedure and
-- can be modified to reflect any custom defaulting logic.
/*****************************************************************************************
 *
 * Package Name     : por_custom_pkg (body)
 * Description      : �w���˗��J�X�^���p�b�P�[�W
 * MD.050           : �w���˗����쐬���鎞�̃f�t�H���g�ŋ��R�[�h�̐ݒ� (MD050_CFO_015_S04)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/07/28    1.0   T.Kobori        [E_�{�ғ�_12184]�Ή� �f�t�H���g�ŃR�[�hID�̐ݒ菈���ǉ�
 *
 *****************************************************************************************/
--
PROCEDURE CUSTOM_DEFAULT_REQ_HEADER (
    req_header_id            IN NUMBER,	-- 1
    old_req_header_id        IN NUMBER,   -- 2
    req_num                  IN VARCHAR2, -- 3
    preparer_id              IN NUMBER, -- 4
    x_req_type                 IN OUT NOCOPY  VARCHAR2, -- 5
    x_emergency_po_num         IN OUT NOCOPY  VARCHAR2, -- 6
    x_approval_status_code     IN OUT NOCOPY  VARCHAR2, -- 7
    x_cancel_flag              IN OUT NOCOPY  VARCHAR2, -- 8
    x_closed_code              IN OUT NOCOPY  VARCHAR2, -- 9
    x_ussgl_transaction_code   IN OUT NOCOPY  VARCHAR2, -- 10
    x_org_id                   IN OUT NOCOPY  NUMBER, -- 11
    x_wf_item_type             IN OUT NOCOPY  VARCHAR2, -- 12
    x_wf_item_key              IN OUT NOCOPY  VARCHAR2, -- 13
    x_pcard_id                 IN OUT NOCOPY  NUMBER, -- 14
    x_attribute1               IN OUT NOCOPY  VARCHAR2, -- 15
    x_attribute2               IN OUT NOCOPY  VARCHAR2, -- 16
    x_attribute3               IN OUT NOCOPY  VARCHAR2, -- 17
    x_attribute4               IN OUT NOCOPY  VARCHAR2, -- 18
    x_attribute5               IN OUT NOCOPY  VARCHAR2, -- 19
    x_attribute6               IN OUT NOCOPY  VARCHAR2, -- 20
    x_attribute7               IN OUT NOCOPY  VARCHAR2, -- 21
    x_attribute8               IN OUT NOCOPY  VARCHAR2, -- 22
    x_attribute9               IN OUT NOCOPY  VARCHAR2, -- 23
    x_attribute10              IN OUT NOCOPY  VARCHAR2, -- 24
    x_attribute11              IN OUT NOCOPY  VARCHAR2, -- 25
    x_attribute12              IN OUT NOCOPY  VARCHAR2, -- 26
    x_attribute13              IN OUT NOCOPY  VARCHAR2, -- 27
    x_attribute14              IN OUT NOCOPY  VARCHAR2, -- 28
    x_attribute15              IN OUT NOCOPY  VARCHAR2, -- 29
    x_return_code                OUT NOCOPY NUMBER, -- 30
    x_error_msg                  OUT NOCOPY VARCHAR2 -- 31
    
  )
  is
BEGIN
   X_RETURN_CODE:=0;
   X_ERROR_MSG:='';
END CUSTOM_DEFAULT_REQ_HEADER;


-- Customize this procedure to add logic for validation of the attribute values
-- on a requisition header. This  would be any custom validation, that would 
-- be in addition to all the validations done for a requisition header.
-- The return_msg and the error_code can be used to return the results of
-- the validation
-- The return code can be used to indicate on which tab the error message
-- needs to be displayed on the Edit Lines page
-- If the result code is 1, error is displayed on the Delivery tab 
-- If the result code is 2, error is displayed on the Billing tab
-- If the result code is 3, error is displayed on the Accounts tab

PROCEDURE CUSTOM_VALIDATE_REQ_HEADER (
    req_header_id            IN  NUMBER, -- 1
    req_num                  IN  VARCHAR2, -- 2
    preparer_id	       IN  NUMBER,	-- 3
    req_type                 IN  VARCHAR2, -- 4
    emergency_po_num         IN  VARCHAR2, -- 5
    approval_status_code     IN  VARCHAR2, -- 6
    cancel_flag              IN  VARCHAR2, -- 7
    closed_code              IN  VARCHAR2, -- 8
    ussgl_transaction_code   IN  VARCHAR2, -- 9
    org_id                   IN  NUMBER, -- 10
    wf_item_type             IN  VARCHAR2, -- 11
    wf_item_key              IN  VARCHAR2, -- 12
    pcard_id                 IN  NUMBER, -- 13
    attribute1               IN  VARCHAR2, -- 14
    attribute2               IN  VARCHAR2, -- 15
    attribute3               IN  VARCHAR2, -- 16
    attribute4               IN  VARCHAR2, -- 17
    attribute5               IN  VARCHAR2, -- 18
    attribute6               IN  VARCHAR2, -- 19
    attribute7               IN  VARCHAR2, -- 20
    attribute8               IN  VARCHAR2, -- 21
    attribute9               IN  VARCHAR2, -- 22
    attribute10              IN  VARCHAR2, -- 23
    attribute11              IN  VARCHAR2, -- 24
    attribute12              IN  VARCHAR2, -- 25
    attribute13              IN  VARCHAR2, -- 26
    attribute14              IN  VARCHAR2, -- 27
    attribute15              IN  VARCHAR2, -- 28
    x_return_code                OUT NOCOPY NUMBER, -- 29
    x_error_msg                  OUT NOCOPY VARCHAR2 -- 30
  )
  IS
BEGIN
   X_RETURN_CODE:=0;
   X_ERROR_MSG:='';
END CUSTOM_VALIDATE_REQ_HEADER;


-- Customize this procedure to add custom defaulting logic for all the 
-- attributes on a requisition line. 
-- This is called when a new line gets added to the requisition.
-- The attribute id's are passed as IN OUT NOCOPY parameters to this procedure and
-- can be modified to reflect any custom defaulting logic.
-- The values corresponding to the id's are recalculated in the calling ReqLine
-- Java class

PROCEDURE CUSTOM_DEFAULT_REQ_LINE (
-- READ ONLY data
    req_header_id            IN NUMBER,	-- 1
    req_line_id              IN NUMBER,	-- 2
    old_req_line_id          IN NUMBER,   -- 3
    line_num                 IN NUMBER,	-- 4

-- header data				   
    preparer_id                IN NUMBER, -- 5
    header_attribute_1         IN VARCHAR2, -- 6
    header_attribute_2         IN VARCHAR2, -- 7
    header_attribute_3         IN VARCHAR2, -- 8
    header_attribute_4         IN VARCHAR2, -- 9
    header_attribute_5         IN VARCHAR2, -- 10
    header_attribute_6         IN VARCHAR2, -- 11
    header_attribute_7         IN VARCHAR2, -- 12
    header_attribute_8         IN VARCHAR2, -- 13
    header_attribute_9         IN VARCHAR2, -- 14
    header_attribute_10        IN VARCHAR2, -- 15
    header_attribute_11        IN VARCHAR2, -- 16
    header_attribute_12        IN VARCHAR2, -- 17
    header_attribute_13        IN VARCHAR2, -- 18
    header_attribute_14        IN VARCHAR2, -- 19
    header_attribute_15        IN VARCHAR2, -- 20

-- line data: update any of the following parameters as default for line
    x_line_type_id             IN OUT NOCOPY  NUMBER, -- 21
    x_item_id                  IN OUT NOCOPY  NUMBER, -- 22
    x_item_revision            IN OUT NOCOPY  VARCHAR2, -- 23
    x_category_id              IN OUT NOCOPY  NUMBER, -- 24
    x_catalog_source           IN OUT NOCOPY  VARCHAR2, -- 25
    x_catalog_type             IN OUT NOCOPY  VARCHAR2, -- 26
    x_currency_code            IN OUT NOCOPY  VARCHAR2, -- 27
    x_currency_unit_price      IN OUT NOCOPY  NUMBER, -- 28
    x_manufacturer_name        IN OUT NOCOPY  VARCHAR2, -- 29
    x_manufacturer_part_num    IN OUT NOCOPY  VARCHAR2, -- 30
    x_deliver_to_loc_id        IN OUT NOCOPY  NUMBER, -- 31
    x_deliver_to_org_id        IN OUT NOCOPY  NUMBER, -- 32
    x_deliver_to_subinv        IN OUT NOCOPY  VARCHAR2, -- 33
    x_destination_type_code    IN OUT NOCOPY  VARCHAR2, -- 34
    x_requester_id             IN OUT NOCOPY  NUMBER, -- 35
    x_encumbered_flag          IN OUT NOCOPY  VARCHAR2, -- 36
    x_hazard_class_id          IN OUT NOCOPY  NUMBER, -- 37
    x_modified_by_buyer        IN OUT NOCOPY  VARCHAR2, -- 38
    x_need_by_date             IN OUT NOCOPY  DATE, -- 39
    x_new_supplier_flag        IN OUT NOCOPY  VARCHAR2, -- 40
    x_on_rfq_flag              IN OUT NOCOPY  VARCHAR2, -- 41
    x_org_id                   IN OUT NOCOPY  NUMBER, -- 42
    x_parent_req_line_id       IN OUT NOCOPY  NUMBER, -- 43
    x_po_line_loc_id           IN OUT NOCOPY  NUMBER, -- 44
    x_qty_cancelled            IN OUT NOCOPY  NUMBER, -- 45
    x_qty_delivered            IN OUT NOCOPY  NUMBER, -- 46
    x_qty_ordered              IN OUT NOCOPY  NUMBER, -- 47
    x_qty_received             IN OUT NOCOPY  NUMBER, -- 48
    x_rate                     IN OUT NOCOPY  NUMBER, -- 49
    x_rate_date                IN OUT NOCOPY  DATE, -- 50
    x_rate_type                IN OUT NOCOPY  VARCHAR2, -- 51
    x_rfq_required             IN OUT NOCOPY  VARCHAR2, -- 52
    x_source_type_code         IN OUT NOCOPY  VARCHAR2, -- 53
    x_spsc_code                IN OUT NOCOPY  VARCHAR2, -- 54
    x_other_category_code      IN OUT NOCOPY  VARCHAR2, -- 55
    x_suggested_buyer_id       IN OUT NOCOPY  NUMBER, -- 56
    x_source_doc_header_id     IN OUT NOCOPY  NUMBER, -- 57
    x_source_doc_line_num      IN OUT NOCOPY  NUMBER, -- 58
    x_source_doc_type_code     IN OUT NOCOPY  VARCHAR2, -- 59
    x_supplier_duns            IN OUT NOCOPY  VARCHAR2, -- 60
    x_supplier_item_num        IN OUT NOCOPY  VARCHAR2, -- 61
    x_taxable_status           IN OUT NOCOPY  VARCHAR2, -- 62
    x_unit_of_measure          IN OUT NOCOPY  VARCHAR2, -- 63
    x_unit_price               IN OUT NOCOPY  NUMBER, -- 64
    x_urgent                   IN OUT NOCOPY  VARCHAR2, -- 65
    x_supplier_contact_id      IN OUT NOCOPY  NUMBER, -- 66
    x_supplier_id              IN OUT NOCOPY  NUMBER, -- 67
    x_supplier_site_id         IN OUT NOCOPY  NUMBER, -- 68
    x_cancel_date              IN OUT NOCOPY  DATE, -- 69
    x_cancel_flag              IN OUT NOCOPY  VARCHAR2, -- 70
    x_closed_code              IN OUT NOCOPY  VARCHAR2, -- 71
    x_closed_date              IN OUT NOCOPY  DATE, -- 72
    x_auto_receive_flag        IN OUT NOCOPY  VARCHAR2, -- 73
    x_pcard_flag               IN OUT NOCOPY  VARCHAR2, -- 74
    x_attribute1               IN OUT NOCOPY  VARCHAR2, -- 75
    x_attribute2               IN OUT NOCOPY  VARCHAR2, -- 76
    x_attribute3               IN OUT NOCOPY  VARCHAR2, -- 77
    x_attribute4               IN OUT NOCOPY  VARCHAR2, -- 78
    x_attribute5               IN OUT NOCOPY  VARCHAR2, -- 79
    x_attribute6               IN OUT NOCOPY  VARCHAR2, -- 80
    x_attribute7               IN OUT NOCOPY  VARCHAR2, -- 81
    x_attribute8               IN OUT NOCOPY  VARCHAR2, -- 82
    x_attribute9               IN OUT NOCOPY  VARCHAR2, -- 83
    x_attribute10              IN OUT NOCOPY  VARCHAR2, -- 84
    x_attribute11              IN OUT NOCOPY  VARCHAR2, -- 85
    x_attribute12              IN OUT NOCOPY  VARCHAR2, -- 86
    x_attribute13              IN OUT NOCOPY  VARCHAR2, -- 87
    x_attribute14              IN OUT NOCOPY  VARCHAR2, -- 88
    x_attribute15              IN OUT NOCOPY  VARCHAR2, -- 89
    X_return_code                OUT NOCOPY NUMBER, -- 90
    X_error_msg                  OUT NOCOPY VARCHAR2, -- 91
    x_supplierContact          IN OUT NOCOPY  VARCHAR2, -- 92
    x_supplierContactPhone     IN OUT NOCOPY  VARCHAR2, -- 93
    x_supplier		       IN OUT NOCOPY  VARCHAR2, -- 94
    x_supplierSite	       IN OUT NOCOPY  VARCHAR2, -- 95
    x_taxCodeId	       IN OUT NOCOPY  NUMBER, -- 96
    x_source_org_id    IN OUT NOCOPY  NUMBER -- 97

  )
  IS
 -- 2014/07/28 ADD START
    cv_prc_name                 CONSTANT VARCHAR2(100) := 'CUSTOM_DEFAULT_REQ_LINE';   -- �v���V�[�W����
    cv_msg_part                 CONSTANT VARCHAR2(3) := ' : ';
    -- ���[�U�[��`��O
    tax_id_not_found            EXCEPTION;                                             -- �ŋ��R�[�h���ݒ�
    -- �A�v���P�[�V�����Z�k��
    cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
    -- ���b�Z�[�W�R�[�h
    cv_msg_cfo_00050            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00050';          -- ��O�G���[
    -- ���[�J���ϐ�
    lv_taxCodeId                AP_TAX_CODES_ALL.TAX_ID%TYPE;                          -- �ŋ��R�[�hID
 -- 2014/07/28 ADD END
BEGIN
   X_RETURN_CODE:=0;
   X_ERROR_MSG:='';
 -- 2014/07/28 ADD START
    --==============================================================
    -- 1.�f�t�H���g�ŋ��R�[�hID�擾
    --==============================================================
    -- �d�����񂪘A�g����Ă���ꍇ
    IF ( x_org_id IS NOT NULL AND x_supplier_id IS NOT NULL AND x_supplier_site_id IS NOT NULL ) THEN
        BEGIN
            SELECT
                atca.tax_id  AS  tax_id                  -- �ŋ��}�X�^.�ŋ��R�[�hID
            INTO
                lv_taxCodeId
            FROM
                ap_tax_codes_all atca                    -- �ŋ��}�X�^
               ,(SELECT
                    CASE
                        WHEN pvs.vat_code  IS NOT NULL THEN pvs.vat_code         -- �d����T�C�g.�ŋ��R�[�h
                        WHEN pv.vat_code   IS NOT NULL THEN pv.vat_code          -- �d����.�ŋ��R�[�h
                    END vat_code
                FROM
                    po_vendors pv                            -- �d����
                   ,po_vendor_sites_all pvs                  -- �d����T�C�g
                WHERE pv.vendor_id            = pvs.vendor_id                   -- �d����ID
                AND pvs.org_id                = x_org_id                        -- �g�DID
                AND pv.vendor_id              = x_supplier_id                   -- �d����ID
                AND pvs.vendor_site_id        = x_supplier_site_id              -- �d����T�C�gID
                ) tax_tbl
            WHERE atca.name               = tax_tbl.vat_code           -- �ŋ��R�[�h
            AND atca.org_id               = x_org_id                   -- �g�DID
            AND atca.start_date          <= SYSDATE                    -- �J�n��
            AND (atca.inactive_date       IS NULL                      -- ������
                OR atca.inactive_date     > SYSDATE                    -- ������
                )
            ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- �Y���f�[�^�����݂��Ȃ��ꍇ�A�����������Ȃ�
                NULL;
        END;
    END IF;
--
    -- �d������ɕR�t���ŋ��R�[�hID���擾�ł��Ȃ������ꍇ
    IF ( x_org_id IS NOT NULL AND lv_taxCodeId IS NULL ) THEN
        BEGIN
            SELECT
                atca.tax_id  AS  tax_id                  -- �ŋ��}�X�^.�ŋ��R�[�hID
            INTO
                lv_taxCodeId
            FROM
                ap_tax_codes_all atca                    -- �ŋ��}�X�^
               ,financials_system_params_all fspa        -- ��v�I�v�V����
            WHERE atca.name               = fspa.vat_code              -- �ŋ��R�[�h
            AND fspa.org_id               = x_org_id                   -- �g�DID
            AND atca.org_id               = x_org_id                   -- �g�DID
            AND atca.start_date          <= SYSDATE                    -- �J�n��
            AND (atca.inactive_date       IS NULL                      -- ������
                OR atca.inactive_date     > SYSDATE                    -- ������
                )
            ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- �Y���f�[�^�����݂��Ȃ��ꍇ
                RAISE tax_id_not_found;
        END;
    END IF;
--
    --==============================================================
    -- 2.�f�t�H���g�ŋ��R�[�hID�̐ݒ�
    --==============================================================
    -- �ŋ��R�[�hID���擾�ł��Ȃ������ꍇ
    IF ( lv_taxCodeId IS NULL ) THEN
        RAISE tax_id_not_found;
    ELSE
        x_taxCodeId := lv_taxCodeId;
    END IF;
--
EXCEPTION
    WHEN tax_id_not_found THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        X_RETURN_CODE:=1;
        X_ERROR_MSG:= xxccp_common_pkg.get_msg(
            iv_application  => cv_appl_name_xxcfo   -- �A�v���P�[�V�����Z�k��
           ,iv_name         => cv_msg_cfo_00050     -- ���b�Z�[�W�R�[�h
        );
    WHEN OTHERS THEN
        X_RETURN_CODE:=1;
        X_ERROR_MSG:= cv_prc_name || cv_msg_part || SQLERRM;
--
 -- 2014/07/28 ADD END
END;


-- Customize this procedure to add logic for validation of the attribute values
-- on a requisition line. This would be any custom validation, that would be 
-- in addition to all the validations done for a requisition line
-- This is called whenever the requisition line gets updated and is called
-- on every page in the checkOUT NOCOPY flow.
-- The return_msg and the error_code can be used to return the results of
-- the validation
-- The return code can be used to indicate on which tab the error message
-- needs to be displayed on the Edit Lines page
-- If the result code is 1, error is displayed on the Delivery tab 
-- If the result code is 2, error is displayed on the Billing tab
-- If the result code is 3, error is displayed on the Accounts tab


PROCEDURE CUSTOM_VALIDATE_REQ_LINE (
  x_req_header_id            IN  NUMBER, -- 1
    x_req_line_id              IN  NUMBER, -- 2
    x_line_num                 IN  NUMBER, -- 3


-- header data				   
    preparer_id                IN NUMBER, -- 4
    header_attribute_1         IN VARCHAR2, -- 5
    header_attribute_2         IN VARCHAR2, -- 6
    header_attribute_3         IN VARCHAR2, -- 7
    header_attribute_4         IN VARCHAR2, -- 8
    header_attribute_5         IN VARCHAR2, -- 9
    header_attribute_6         IN VARCHAR2, -- 10
    header_attribute_7         IN VARCHAR2, -- 11
    header_attribute_8         IN VARCHAR2, -- 12
    header_attribute_9         IN VARCHAR2, -- 13
    header_attribute_10        IN VARCHAR2, -- 14
    header_attribute_11        IN VARCHAR2, -- 15
    header_attribute_12        IN VARCHAR2, -- 16
    header_attribute_13        IN VARCHAR2, -- 17
    header_attribute_14        IN VARCHAR2, -- 18
    header_attribute_15        IN VARCHAR2, -- 19

-- line data
    line_type_id             IN  NUMBER, -- 20
    item_id                  IN  NUMBER, -- 21
    item_revision            IN  VARCHAR2, -- 22
    category_id              IN  NUMBER, -- 23
    catalog_source           IN  VARCHAR2, -- 24
    catalog_type             IN  VARCHAR2, -- 25
    currency_code            IN  VARCHAR2, -- 26
    currency_unit_price      IN  NUMBER, -- 27
    manufacturer_name        IN  VARCHAR2, --28
    manufacturer_part_num    IN  VARCHAR2, -- 29
    deliver_to_loc_id        IN  NUMBER, -- 30
    deliver_to_org_id        IN  NUMBER, -- 31
    deliver_to_subinv        IN  VARCHAR2, -- 32
    destination_type_code    IN  VARCHAR2, -- 33
    requester_id             IN  NUMBER, -- 34
    encumbered_flag          IN  VARCHAR2, -- 35
    hazard_class_id          IN  NUMBER, -- 36
    modified_by_buyer        IN  VARCHAR2, -- 37
    need_by_date             IN  DATE, -- 38
    new_supplier_flag        IN  VARCHAR2, -- 39
    on_rfq_flag              IN  VARCHAR2, -- 40
    org_id                   IN  NUMBER, -- 41
    parent_req_line_id       IN  NUMBER, -- 42
    po_line_loc_id           IN  NUMBER, -- 43
    qty_cancelled            IN  NUMBER, -- 44
    qty_delivered            IN  NUMBER, -- 45
    qty_ordered              IN  NUMBER, -- 46
    qty_received             IN  NUMBER, -- 47
    rate                     IN  NUMBER, -- 48
    rate_date                IN  DATE, -- 49
    rate_type                IN  VARCHAR2, -- 50
    rfq_required             IN  VARCHAR2, -- 51
    source_type_code         IN  VARCHAR2, -- 52
    spsc_code                IN  VARCHAR2, -- 53
    other_category_code      IN  VARCHAR2, -- 54
    suggested_buyer_id       IN OUT NOCOPY NUMBER, -- 55
    source_doc_header_id     IN  NUMBER, -- 56
    source_doc_line_num      IN  NUMBER, -- 57
    source_doc_type_code     IN  VARCHAR2, -- 58
    supplier_duns            IN  VARCHAR2, -- 59
    supplier_item_num        IN  VARCHAR2, -- 60
    taxable_status           IN  VARCHAR2, -- 61
    unit_of_measure          IN  VARCHAR2, -- 62
    unit_price               IN  NUMBER, -- 63
    urgent                   IN  VARCHAR2, -- 64
    supplier_contact_id      IN  NUMBER, -- 65
    supplier_id              IN  NUMBER, -- 66
    supplier_site_id         IN  NUMBER, -- 67
    cancel_date              IN  DATE, -- 68
    cancel_flag              IN  VARCHAR2, -- 69
    closed_code              IN  VARCHAR2, -- 70
    closed_date              IN  DATE, -- 71
    auto_receive_flag        IN  VARCHAR2, -- 72
    pcard_flag               IN  VARCHAR2, -- 73
    attribute1               IN  VARCHAR2, -- 74
    attribute2               IN  VARCHAR2, -- 75
    attribute3               IN  VARCHAR2, -- 76
    attribute4               IN  VARCHAR2, -- 77
    attribute5               IN  VARCHAR2, -- 78
    attribute6               IN  VARCHAR2, -- 79
    attribute7               IN  VARCHAR2, -- 80
    attribute8               IN  VARCHAR2, -- 81
    attribute9               IN  VARCHAR2, -- 82
    attribute10              IN  VARCHAR2, -- 83
    attribute11              IN  VARCHAR2, -- 84
    attribute12              IN  VARCHAR2, -- 85
    attribute13              IN  VARCHAR2, -- 86
    attribute14              IN  VARCHAR2, -- 87
    attribute15              IN  VARCHAR2, -- 88
    x_taxCodeId	           IN NUMBER,    -- 89
    x_return_code            OUT NOCOPY NUMBER, -- 90 no error
    x_error_msg              OUT NOCOPY VARCHAR2, -- 91
    x_source_org_id          IN  NUMBER -- 92
  )
  IS
BEGIN
    X_RETURN_CODE:=0;
    X_ERROR_MSG:='';
END;




-- Customize this procedure to add custom defaulting logic for all the 
-- attributes on a requisition distribution. 
-- This is called when a new distribution gets added to the requisition.
-- The attribute id's are passed as IN OUT NOCOPY parameters to this procedure and
-- can be modified to reflect any custom defaulting logic.

PROCEDURE CUSTOM_DEFAULT_REQ_DIST (
    x_distribution_id       IN NUMBER,  -- 1
    x_old_distribution_id   IN NUMBER,  -- 2
    x_code_combination_id   IN OUT NOCOPY   NUMBER, -- 3
    x_budget_account_id   IN OUT NOCOPY   NUMBER, -- 4
    x_variance_account_id   IN OUT NOCOPY   NUMBER, -- 5
    x_accrual_account_id   IN OUT NOCOPY   NUMBER, -- 6
    project_id		      IN OUT NOCOPY NUMBER, -- 7
    task_id		      IN OUT NOCOPY NUMBER, -- 8
    expenditure_type	      IN OUT NOCOPY VARCHAR2, -- 9
    expenditure_organization_id IN OUT NOCOPY NUMBER, -- 10
    expenditure_item_date    IN OUT NOCOPY DATE, -- 11
    award_id                 IN OUT NOCOPY NUMBER, -- 12
    gl_encumbered_date	     IN OUT NOCOPY DATE,	-- 13
    gl_period_name           IN OUT NOCOPY VARCHAR2, -- 14
    gl_cancelled_date        IN OUT NOCOPY DATE, -- 15
    gl_closed_date           IN OUT NOCOPY DATE,--16
    gl_date                  IN OUT NOCOPY DATE,--17
    gl_encumbered_period     IN OUT NOCOPY VARCHAR2,--18
    recovery_rate            IN OUT NOCOPY NUMBER, -- 19
    tax_recovery_override_flag IN OUT NOCOPY VARCHAR2, -- 20
    chart_of_accounts_id     IN  NUMBER, -- 21
    category_id 	     IN  NUMBER, -- 22
    catalog_source           IN  VARCHAR2, -- 23
    catalog_type             IN  VARCHAR2, -- 24
    destination_type_code    IN  VARCHAR2, -- 25
    deliver_to_location_id   IN  NUMBER, -- 26
    destination_organization_id IN NUMBER, -- 27
    destination_subinventory IN  VARCHAR2, -- 28
    item_id			IN  NUMBER, -- 29
    sob_id                      IN NUMBER, -- 30
    currency_code               IN VARCHAR2, -- 31
    currency_unit_price         IN NUMBER, -- 32
    manufacturer_name           IN VARCHAR2, -- 33
    manufacturer_part_num       IN VARCHAR2,-- 34
    need_by_date                IN DATE, -- 35
    new_supplier_flag           IN VARCHAR2, -- 36
    business_org_id             IN NUMBER,    -- 37
    org_id                      IN NUMBER, -- 38
    employee_id                 IN NUMBER, -- 39
    employee_org_id       IN      NUMBER,  -- 40
    default_code_combination_id IN NUMBER, -- 41
    parent_req_line_id       IN  NUMBER, -- 42
    qty_cancelled            IN  NUMBER, -- 43
    qty_delivered            IN  NUMBER, -- 44
    qty_ordered              IN  NUMBER, -- 45
    qty_received             IN  NUMBER, -- 46
    rate                     IN  NUMBER, -- 47
    rate_date                IN  DATE, -- 48
    rate_type                IN  VARCHAR2, -- 49
    source_type_code         IN  VARCHAR2, -- 50
    spsc_code                IN  VARCHAR2, -- 51
    suggested_buyer_id       IN  NUMBER, -- 52
    source_doc_header_id     IN  NUMBER, -- 53
    source_doc_line_num      IN  NUMBER, -- 54
    source_doc_type_code     IN  VARCHAR2, -- 55
    supplier_item_num        IN  VARCHAR2, -- 56
    taxable_status           IN  VARCHAR2, -- 57
    unit_of_measure          IN  VARCHAR2, -- 58
    unit_price               IN  NUMBER, -- 59
    supplier_contact_id      IN  NUMBER, -- 60
    supplier_id              IN  NUMBER, -- 61
    supplier_site_id         IN  NUMBER, -- 62
    pcard_flag               IN  VARCHAR2, -- 63
    line_type_id	     IN  NUMBER, -- 64
    taxCodeId	             IN   NUMBER, -- 65		 		     
    results_billable_flag    IN VARCHAR2,-- 66
    preparer_id	   	     IN  NUMBER, -- 67
    deliver_to_person_id	IN  NUMBER, -- 68
    po_encumberance_flag	IN  VARCHAR2, -- 69
    DATE_FORMAT		IN  VARCHAR2,	-- 70
    header_att1		  IN  VARCHAR2,	-- 71
    header_att2		  IN  VARCHAR2,	-- 72
    header_att3		  IN  VARCHAR2,	-- 73
    header_att4		  IN  VARCHAR2,	-- 74
    header_att5		  IN  VARCHAR2,	-- 75
    header_att6		  IN  VARCHAR2,	-- 76
    header_att7		  IN  VARCHAR2,	-- 77
    header_att8		  IN  VARCHAR2,	-- 78
    header_att9		  IN  VARCHAR2,	-- 79
    header_att10	  IN  VARCHAR2,	-- 80
    header_att11	  IN  VARCHAR2,	-- 81
    header_att12	  IN  VARCHAR2,	-- 82
    header_att13          IN  VARCHAR2,	-- 83
    header_att14	  IN  VARCHAR2,	-- 84
    header_att15	  IN  VARCHAR2,	-- 85
    line_att1		  IN  VARCHAR2,	-- 86
    line_att2		  IN  VARCHAR2,	-- 87
    line_att3		  IN  VARCHAR2,	-- 88
    line_att4		  IN  VARCHAR2,	-- 89
    line_att5		  IN  VARCHAR2,	-- 90
    line_att6		  IN  VARCHAR2,	-- 91
    line_att7		  IN  VARCHAR2,	-- 92
    line_att8		  IN  VARCHAR2,	-- 93
    line_att9		  IN  VARCHAR2,	-- 94
    line_att10		  IN  VARCHAR2,	-- 95
    line_att11		  IN  VARCHAR2,	-- 96
    line_att12		  IN  VARCHAR2,	-- 97
    line_att13		  IN  VARCHAR2,	-- 98
    line_att14		  IN  VARCHAR2,	-- 99
    line_att15		  IN  VARCHAR2,	-- 100
    distribution_att1	  IN OUT NOCOPY  VARCHAR2, -- 101
    distribution_att2	  IN OUT NOCOPY  VARCHAR2, -- 102
    distribution_att3	  IN OUT NOCOPY  VARCHAR2, -- 103
    distribution_att4	  IN OUT NOCOPY  VARCHAR2, -- 104
    distribution_att5	  IN OUT NOCOPY  VARCHAR2, -- 105
    distribution_att6	  IN OUT NOCOPY  VARCHAR2, -- 106
    distribution_att7	  IN OUT NOCOPY  VARCHAR2, -- 107
    distribution_att8	  IN OUT NOCOPY  VARCHAR2, -- 108
    distribution_att9	  IN OUT NOCOPY  VARCHAR2, -- 109
    distribution_att10	  IN OUT NOCOPY  VARCHAR2, -- 110
    distribution_att11	  IN OUT NOCOPY  VARCHAR2, -- 111
    distribution_att12	  IN OUT NOCOPY  VARCHAR2, -- 112
    distribution_att13	  IN OUT NOCOPY  VARCHAR2, -- 113
    distribution_att14	  IN OUT NOCOPY  VARCHAR2, -- 114
    distribution_att15	  IN OUT NOCOPY  VARCHAR2, -- 115
    result_code           OUT NOCOPY     NUMBER,  -- 116
    x_error_msg           OUT NOCOPY     VARCHAR2 -- 117
)

IS
BEGIN

   RESULT_CODE:=0;
   X_ERROR_MSG:='';

END;

-- Customize this procedure to add logic for validation of the attribute values
-- on a requisition distribution. This would be any custom validation, that 
-- would be in addition to all the validations done for a requisition 
-- distribution. 
-- The return_msg and the error_code can be used to return the results of
-- the validation
-- The return code can be used to indicate on which tab the error message
-- needs to be displayed on the Edit Lines page
-- If the result code is 1, error is displayed on the Delivery tab 
-- If the result code is 2, error is displayed on the Billing tab
-- If the result code is 3, error is displayed on the Accounts tab

PROCEDURE CUSTOM_VALIDATE_REQ_DIST (

    x_distribution_id IN NUMBER, -- 1
    x_code_combination_id   IN   NUMBER, -- 2
    x_budget_account_id   IN    NUMBER, -- 3
    x_variance_account_id   IN   NUMBER, -- 4
    x_accrual_account_id   IN    NUMBER, -- 5
    project_id		      IN NUMBER, -- 6
    task_id		      IN NUMBER, -- 7
    expenditure_type	      IN VARCHAR2, -- 8
    expenditure_organization_id IN NUMBER, -- 9
    expenditure_item_date    IN DATE, -- 10
    award_id                 IN NUMBER, -- 11
    gl_encumbered_date	     IN DATE,	-- 12
    gl_period_name           IN VARCHAR2, -- 13
    gl_cancelled_date        IN DATE, -- 14
    gl_closed_date           IN DATE,--15
    gl_date                  IN DATE,--16
    gl_encumbered_period     IN VARCHAR2,--17
    recovery_rate            IN NUMBER, -- 18
    tax_recovery_override_flag IN VARCHAR2, -- 19
    chart_of_accounts_id     IN  NUMBER, -- 20
    category_id 	     IN  NUMBER, -- 21
    catalog_source           IN  VARCHAR2, -- 22
    catalog_type             IN  VARCHAR2, -- 23
    destination_type_code    IN  VARCHAR2, -- 24
    deliver_to_location_id   IN  NUMBER, -- 25
    destination_organization_id IN NUMBER, -- 26
    destination_subinventory IN  VARCHAR2, -- 27
    item_id			IN  NUMBER, -- 28
    sob_id                      IN NUMBER, -- 29
    currency_code               IN VARCHAR2, -- 30
    currency_unit_price         IN NUMBER, -- 31
    manufacturer_name           IN VARCHAR2, -- 32
    manufacturer_part_num       IN VARCHAR2,-- 33
    need_by_date                IN DATE, -- 34
    new_supplier_flag           IN VARCHAR2, -- 35
    business_org_id             IN NUMBER,    -- 36
    org_id                      IN NUMBER, -- 37
    employee_id                 IN NUMBER, -- 38
    employee_org_id       IN      NUMBER,  -- 39
    default_code_combination_id IN NUMBER, -- 40
    parent_req_line_id       IN  NUMBER, -- 41
    qty_cancelled            IN  NUMBER, -- 42
    qty_delivered            IN  NUMBER, -- 43
    qty_ordered              IN  NUMBER, -- 44
    qty_received             IN  NUMBER, -- 45
    rate                     IN  NUMBER, -- 46
    rate_date                IN  DATE, -- 47
    rate_type                IN  VARCHAR2, -- 48
    source_type_code         IN  VARCHAR2, -- 49
    spsc_code                IN  VARCHAR2, -- 50
    suggested_buyer_id       IN  NUMBER, -- 51
    source_doc_header_id     IN  NUMBER, -- 52
    source_doc_line_num      IN  NUMBER, -- 53
    source_doc_type_code     IN  VARCHAR2, -- 54
    supplier_item_num        IN  VARCHAR2, -- 55
    taxable_status           IN  VARCHAR2, -- 56
    unit_of_measure          IN  VARCHAR2, -- 57
    unit_price               IN  NUMBER, -- 58
    supplier_contact_id      IN  NUMBER, -- 59
    supplier_id              IN  NUMBER, -- 60
    supplier_site_id         IN  NUMBER, -- 61
    pcard_flag               IN  VARCHAR2, -- 62
    line_type_id	     IN  NUMBER, -- 63
    taxCodeId	             IN   NUMBER, -- 64		 		    
    results_billable_flag    IN VARCHAR2,-- 65
    preparer_id	   	     IN  NUMBER, -- 66
    deliver_to_person_id	IN  NUMBER, -- 67
    po_encumberance_flag	IN  VARCHAR2, -- 68
    DATE_FORMAT		IN  VARCHAR2,	-- 69
    header_att1		  IN  VARCHAR2,	-- 70
    header_att2		  IN  VARCHAR2,	-- 71
    header_att3		  IN  VARCHAR2,	-- 72
    header_att4		  IN  VARCHAR2,	-- 73
    header_att5		  IN  VARCHAR2,	-- 74
    header_att6		  IN  VARCHAR2,	-- 75
    header_att7		  IN  VARCHAR2,	-- 76
    header_att8		  IN  VARCHAR2,	-- 77
    header_att9		  IN  VARCHAR2,	-- 78
    header_att10	  IN  VARCHAR2,	-- 79
    header_att11	  IN  VARCHAR2,	-- 80
    header_att12	  IN  VARCHAR2,	-- 81
    header_att13          IN  VARCHAR2,	-- 82
    header_att14	  IN  VARCHAR2,	-- 83
    header_att15	  IN  VARCHAR2,	-- 84
    line_att1		  IN  VARCHAR2,	-- 85
    line_att2		  IN  VARCHAR2,	-- 86
    line_att3		  IN  VARCHAR2,	-- 87
    line_att4		  IN  VARCHAR2,	-- 88
    line_att5		  IN  VARCHAR2,	-- 89
    line_att6		  IN  VARCHAR2,	-- 90
    line_att7		  IN  VARCHAR2,	-- 91
    line_att8		  IN  VARCHAR2,	-- 92
    line_att9		  IN  VARCHAR2,	-- 93
    line_att10		  IN  VARCHAR2,	-- 94
    line_att11		  IN  VARCHAR2,	-- 95
    line_att12		  IN  VARCHAR2,	-- 96
    line_att13		  IN  VARCHAR2,	-- 97
    line_att14		  IN  VARCHAR2,	-- 98
    line_att15		  IN  VARCHAR2,	-- 99
    distribution_att1	  IN   VARCHAR2, -- 100
    distribution_att2	  IN   VARCHAR2, -- 101
    distribution_att3	  IN   VARCHAR2, -- 102
    distribution_att4	  IN   VARCHAR2, -- 103
    distribution_att5	  IN   VARCHAR2, -- 104
    distribution_att6	  IN   VARCHAR2, -- 105
    distribution_att7	  IN   VARCHAR2, -- 106
    distribution_att8	  IN   VARCHAR2, -- 107
    distribution_att9	  IN   VARCHAR2, -- 108
    distribution_att10	  IN   VARCHAR2, -- 109
    distribution_att11	  IN   VARCHAR2, -- 110
    distribution_att12	  IN   VARCHAR2, -- 111
    distribution_att13	  IN   VARCHAR2, -- 112
    distribution_att14	  IN   VARCHAR2, -- 113
    distribution_att15	  IN   VARCHAR2, -- 114
    result_code           OUT NOCOPY     NUMBER,  -- 115
    x_error_msg           OUT NOCOPY     VARCHAR2 -- 116
)
IS
BEGIN
   RESULT_CODE:=0;
   X_ERROR_MSG:='';

END;


-- Customize this procedure to handle updates to charge accounts.
-- The caller passes the charge account segments values in p_seg_vals,
-- and the new segments values should be returned in the same parameter.
-- Null is passed for the value of the read-only and hidden segments.
-- p_changed_seg is the index of the segment that the user changed this time.
-- p_orig_ccid is the CCID in the distribution before any user changes.
-- Any changes made by the user after the last submit event are not reflected
-- in p_orig_ccid.

PROCEDURE CUSTOM_UPDATE_CHARGE_ACCOUNT(
  p_orig_ccid   IN     NUMBER, -- the code-combination ID before any user changes
  p_changed_seg IN     NUMBER, -- index of the changed segment (starts at 0)
  p_seg_vals    IN OUT NOCOPY POR_CHARGE_ACCT_SEG_TBL_TYPE, -- table of segment values
  result_code      OUT NOCOPY NUMBER,
  x_error_msg      OUT NOCOPY VARCHAR2
)
IS
BEGIN
  result_code := 0;
  x_error_msg := '';
END;

				
END POR_CUSTOM_PKG;
/
COMMIT;
EXIT;

