/*============================================================================
* �t�@�C���� : XxcsoContractRegistAMImpl
* �T�v����   : ���̋@�ݒu�_����o�^��ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.5
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
* 2009-02-16 1.1  SCS�������l  [CT1-008]BM�w��`�F�b�N�{�b�N�X�s���Ή�
* 2009-02-23 1.1  SCS�������l  [CT1-021]���t��R�[�h�擾�s���Ή�
*                              [CT1-022]�������擾�s���Ή�
* 2009-04-08 1.2  SCS�������l  [ST��QT1_0364]�d����d���`�F�b�N�C���Ή�
* 2010-01-26 1.3  SCS�������  [E_�{�ғ�_01314]�_�񏑔������K�{�Ή�
* 2010-01-20 1.4  SCS�������  [E_�{�ғ�_01176]������ʑΉ�
* 2010-02-09 1.5  SCS�������  [E_�{�ғ�_01538]�_�񏑂̕����m��Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistInitUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistPropertyUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistReflectUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistValidateUtils;

import java.sql.SQLException;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.server.ViewLinkImpl;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;

import oracle.sql.NUMBER;


/*******************************************************************************
 * ���̋@�ݒu�_����̕ۑ��^�m����s�����߂̃A�v���P�[�V�����E���W���[���N���X�B
 * @author  SCS�������l
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractRegistAMImpl()
  {
  }

  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��i�V�K�쐬�j�B
   * @param spDecisionHeaderId   SP�ꌈ�w�b�_ID
   * @param contractManagementId �_��Ǘ�ID
   *****************************************************************************
   */
  public void initDetailsCreate(
    String spDecisionHeaderId
   ,String contractManagementId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoLoginUserSummaryVOImpl userVo
      = getXxcsoLoginUserSummaryVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserSummaryVO1");
    }

    XxcsoContractCreateInitVOImpl createVo
      = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    XxcsoSalesCondSummaryVOImpl salesCondVo
      = getXxcsoSalesCondSummaryVO1();
    if ( salesCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesCondSummaryVOImpl");
    }

    XxcsoContainerCondSummaryVOImpl contCondVo
      = getXxcsoContainerCondSummaryVO1();
    if ( contCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContainerCondSummaryVOImpl");
    }

    XxcsoInitBmInfoSummaryVOImpl initBmVo
      = getXxcsoInitBmInfoSummaryVO1();
    if ( initBmVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInitBmInfoSummaryVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }


    XxcsoContractRegistInitUtils.initCreate(
      txn
     ,spDecisionHeaderId
     ,pageRenderVo
     ,userAuthVo
     ,userVo
     ,createVo
     ,salesCondVo
     ,contCondVo
     ,initBmVo
     ,mngVo
     ,cntrctVo
     ,dest1Vo
     ,dest2Vo
     ,dest3Vo
     ,bank1Vo
     ,bank2Vo
     ,bank3Vo
     ,spCust1Vo
     ,spCust2Vo
     ,spCust3Vo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��i�X�V�j�B
   * @param spDecisionHeaderId   SP�ꌈ�w�b�_ID
   * @param contractManagementId �_��Ǘ�ID
   *****************************************************************************
   */
  public void initDetailsUpdate(
    String spDecisionHeaderId
   ,String contractManagementId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoLoginUserSummaryVOImpl userVo
      = getXxcsoLoginUserSummaryVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserSummaryVO1");
    }

    XxcsoContractCreateInitVOImpl createVo
      = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    XxcsoSalesCondSummaryVOImpl salesCondVo
      = getXxcsoSalesCondSummaryVO1();
    if ( salesCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesCondSummaryVOImpl");
    }

    XxcsoContainerCondSummaryVOImpl contCondVo
      = getXxcsoContainerCondSummaryVO1();
    if ( contCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContainerCondSummaryVOImpl");
    }

    XxcsoInitBmInfoSummaryVOImpl initBmVo
      = getXxcsoInitBmInfoSummaryVO1();
    if ( initBmVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInitBmInfoSummaryVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }

    XxcsoContractRegistInitUtils.initUpdate(
      txn
     ,contractManagementId
     ,spDecisionHeaderId
     ,pageRenderVo
     ,userAuthVo
     ,userVo
     ,createVo
     ,salesCondVo
     ,contCondVo
     ,initBmVo
     ,mngVo
     ,cntrctVo
     ,dest1Vo
     ,dest2Vo
     ,dest3Vo
     ,bank1Vo
     ,bank2Vo
     ,bank3Vo
     ,spCust1Vo
     ,spCust2Vo
     ,spCust3Vo
    );
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��i�R�s�[�j�B
   * @param spDecisionHeaderId   SP�ꌈ�w�b�_ID
   * @param contractManagementId �_��Ǘ�ID
   *****************************************************************************
   */
  public void initDetailsCopy(
    String spDecisionHeaderId
   ,String contractManagementId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoLoginUserSummaryVOImpl userVo
      = getXxcsoLoginUserSummaryVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserSummaryVO1");
    }

    XxcsoContractCreateInitVOImpl createVo
      = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    XxcsoSalesCondSummaryVOImpl salesCondVo
      = getXxcsoSalesCondSummaryVO1();
    if ( salesCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesCondSummaryVOImpl");
    }

    XxcsoContainerCondSummaryVOImpl contCondVo
      = getXxcsoContainerCondSummaryVO1();
    if ( contCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContainerCondSummaryVOImpl");
    }

    XxcsoInitBmInfoSummaryVOImpl initBmVo
      = getXxcsoInitBmInfoSummaryVO1();
    if ( initBmVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInitBmInfoSummaryVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo2
      = getXxcsoContractManagementFullVO2();
    if ( mngVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO2");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo2
      = getXxcsoBm1DestinationFullVO2();
    if ( dest1Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO2");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo2
      = getXxcsoBm2DestinationFullVO2();
    if ( dest2Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO2");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo2
      = getXxcsoBm3DestinationFullVO2();
    if ( dest3Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO2");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo2
      = getXxcsoBm1BankAccountFullVO2();
    if ( bank1Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO2");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo2
      = getXxcsoBm2BankAccountFullVO2();
    if ( bank2Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO2");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo2
      = getXxcsoBm3BankAccountFullVO2();
    if ( bank3Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO2");
    }

    XxcsoContractRegistInitUtils.initCopy(
      txn
     ,contractManagementId
     ,spDecisionHeaderId
     ,pageRenderVo
     ,userAuthVo
     ,userVo
     ,createVo
     ,salesCondVo
     ,contCondVo
     ,initBmVo
     ,mngVo
     ,cntrctVo
     ,dest1Vo
     ,dest2Vo
     ,dest3Vo
     ,bank1Vo
     ,bank2Vo
     ,bank3Vo
     ,spCust1Vo
     ,spCust2Vo
     ,spCust3Vo
     ,mngVo2
     ,dest1Vo2
     ,dest2Vo2
     ,dest3Vo2
     ,bank1Vo2
     ,bank2Vo2
     ,bank3Vo2
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �\�������ݒ菈���ł��B
   *****************************************************************************
   */
  public void setAttributeProperty()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoPageRenderVOImpl pageRenderVo = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCreateInitVOImpl createVo = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    // �{����
    XxcsoContractRegistPropertyUtils.setAttributeProperty(
      pageRenderVo
     ,userAuthVo
     ,mngVo
     ,createVo
    );

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * �|�b�v���X�g�̏����������ł��B
   *****************************************************************************
   */
  public void initPopList()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �_�񏑃t�H�[�}�b�g
    XxcsoLookupListVOImpl contractFormatVo = getXxcsoContractFormatListVO();
    if ( contractFormatVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractFormatListVO");
    }

    contractFormatVo.initQuery(
      "XXCSO1_CONTRACT_FORMAT"
     ,"lookup_code"
    );

    // �X�e�[�^�X
    XxcsoLookupListVOImpl contractStatusVo = getXxcsoContractStatusListVO();
    if ( contractStatusVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractStatusListVO");
    }

    contractStatusVo.initQuery(
      "XXCSO1_CONTRACT_STATUS"
     ,"lookup_code"
    );

    // ���t�^�C�v�i���ߓ��A�U�����j
    XxcsoLookupListVOImpl daysListVo = getXxcsoDaysListVO();
    if ( daysListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDaysListVO");
    }

    daysListVo.initQuery(
      "XXCSO1_DAYS_TYPE"
     ,"TO_NUMBER(lookup_code)"
    );

    // ���^�C�v�i�U�����j
    XxcsoLookupListVOImpl monthsListVo = getXxcsoMonthsListVO();
    if ( monthsListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoMonthsListVO");
    }

    monthsListVo.initQuery(
      "XXCSO1_MONTHS_TYPE"
     ,"lookup_code"
    );

    // �_������\���o
    XxcsoLookupListVOImpl cancellationListVo
      = getXxcsoCancellationListVO();
    if ( cancellationListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCancellationListVO");
    }

    cancellationListVo.initQuery(
      "XXCSO1_CANCELLATION_MONTH"
     ,"lookup_code"
    );

    // �U���萔�����S
    XxcsoLookupListVOImpl transferFeeListVo
      = getXxcsoTransferFeeListVO();
    if ( transferFeeListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferFeeListVO");
    }

    transferFeeListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // �x�����@�A���׏�
    XxcsoLookupListVOImpl bmPaymentListVo = getXxcsoBmPaymentListVO();
    if ( bmPaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentListVO");
    }

    bmPaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"(attribute1 = 'Y') AND (lookup_code <> '5')"
     ,"lookup_code"
    );

    // �������
    XxcsoLookupListVOImpl kozaListVo = getXxcsoKozaListVO();
    if ( kozaListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoKozaListVO");
    }

    kozaListVo.initQuery(
// 2010-01-20 [E_�{�ғ�_01176] Add Start
      //"JP_BANK_ACCOUNT_TYPE"
      "XXCSO1_KOZA_TYPE"
// 2010-01-20 [E_�{�ғ�_01176] Add End
     ,"lookup_code"
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ����{�^����������
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    this.rollback();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �K�p�{�^����������
   *****************************************************************************
   */
  public void handleApplyButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    this.validateAll(false);

    mMessage = this.validateBmAccountInfo();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �m��{�^����������
   *****************************************************************************
   */
  public void handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    this.validateAll(true);

    mMessage = this.validateBmAccountInfo();

    XxcsoUtils.debug(txn, "[END]");

  }


  /*****************************************************************************
   * PDF�쐬�{�^����������
   *****************************************************************************
   */
  public HashMap handlePrintPdfButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    // �_�񏑃t�H�[�}�b�g�ɂ��̑����I������Ă���ꍇ�A�G���[
    if ( XxcsoContractRegistConstants.FORMAT_OTHER.equals(
          mngRow.getContractFormat()
         )
    )
    {
      throw
        XxcsoMessage.createErrorMessage( XxcsoConstants.APP_XXCSO1_00448 );
    }

    // �X�e�[�^�X���쐬���̏ꍇ�͓��̓`�F�b�N���{
    if (XxcsoContractRegistConstants.STS_INPUT.equals( mngRow.getStatus() ) )
    {
 // 2010-01-26 [E_�{�ғ�_01314] Add Start
      //if ( getTransaction().isDirty() )
      //{
// 2010-01-26 [E_�{�ғ�_01314] Add End
      this.validateAll(false);
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
      /////////////////////////////////////
      // ���؏����F�c�a�l����
      /////////////////////////////////////
      OAException oaeMsg = null;

      oaeMsg
        = XxcsoContractRegistValidateUtils.validateDb(
            txn
           ,mngVo
          );
      if (oaeMsg != null)
      {
        throw oaeMsg;
      }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
      // �ۑ����������s���܂��B
      this.commit();
// 2010-01-26 [E_�{�ғ�_01314] Add Start
      //}
// 2010-01-26 [E_�{�ғ�_01314] Add End
    }
    else
    {
      this.rollback();
    }

    // /////////////////
    // PDF�쐬����Start
    // /////////////////
    OracleCallableStatement stmt      = null;
    NUMBER                  requestId = null;

    // �R���J�����g�̎��s
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := fnd_request.submit_request(");
      sql.append("         application       => 'XXCSO'");
      sql.append("        ,program           => 'XXCSO010A04C'");
      sql.append("        ,description       => NULL");
      sql.append("        ,start_time        => NULL");
      sql.append("        ,sub_request       => FALSE");
      sql.append("        ,argument1         => :2");
      sql.append("       );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, mngRow.getContractManagementId().stringValue());

      stmt.execute();

      requestId = stmt.getNUMBER(1);
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    // �R���J�����g�̃��N�G�X�gID���G���[���b�Z�[�W�̎擾
    if ( NUMBER.zero().equals(requestId) )
    {
      try
      {
        StringBuffer sql = new StringBuffer(50);
        sql.append("BEGIN fnd_message.retrieve(:1); END;");

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.VARCHAR);

        stmt.execute();

        String errmsg = stmt.getString(1);

        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00310
           ,XxcsoConstants.TOKEN_CONC
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT
           ,XxcsoConstants.TOKEN_CONCMSG
           ,errmsg
          );
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT
          );
      }
      finally
      {
          try
          {
            if ( stmt != null )
            {
              stmt.close();
            }
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
          }
      }
    }

    this.commit();

    // APP_XXCSO1_00001��record�ɐݒ肷�镶��
    StringBuffer sbRecord = new StringBuffer();
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_CONTRACT_REGIST );
    sbRecord.append( XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT );
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_SEP_LEFT );
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_REQUEST_ID );
    sbRecord.append( requestId.stringValue() );
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_SEP_RIGHT );

    // ����I�����b�Z�[�W
    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,new String( sbRecord )
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoContractRegistConstants.TOKEN_VALUE_START
        );

    // URL�p�����[�^�pMap
    HashMap params = new HashMap(3);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoContractRegistConstants.MODE_UPDATE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,mngRow.getSpDecisionHeaderId().toString()
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY2
     ,mngRow.getContractManagementId().toString()
    );

    // AM�߂�l�pMap�ւ̐ݒ�
    HashMap returnMap = new HashMap(2);
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_URL_PARAM
     ,params
    );
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_MESSAGE
     ,msg
    );

    XxcsoUtils.debug(txn, "[END]");

    return returnMap;

  }

  /*****************************************************************************
   * �m�F�_�C�A���OOK�{�^������������
   * �i�_�C�A���O���o�͎����o�^�����Ƃ���Call�����j
   * @param   actionValue �ۑ�or�m��̕�����
   * @return  HashMap     �ĕ\���p���i�[Map
   *****************************************************************************
   */
  public HashMap handleConfirmOkButton(String actionValue)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

// 2010-02-09 [E_�{�ғ�_01538] Mod Start
    /////////////////////////////////////
    // ���؏����F�c�a�l����
    /////////////////////////////////////
    OAException oaeMsg = null;

    oaeMsg
      = XxcsoContractRegistValidateUtils.validateDb(
          txn
         ,mngVo
        );
    if (oaeMsg != null)
    {
      throw oaeMsg;
    }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
    // �m��{�^�������̏ꍇ
    if ( XxcsoConstants.TOKEN_VALUE_DECISION.equals(actionValue) )
    {
      // �X�e�[�^�X
      mngRow.setStatus(XxcsoContractRegistConstants.STS_FIX);
      // �}�X�^�A�g�t���O
      mngRow.setCooperateFlag(XxcsoContractRegistConstants.COOPERATE_NONE);
    }
    // �K�p�{�^�������̏ꍇ
    else
    {
      // �X�e�[�^�X
      mngRow.setStatus(XxcsoContractRegistConstants.STS_INPUT);
    }

    this.commit();

    // ����I�����b�Z�[�W
    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoConstants.TOKEN_VALUE_CONTRACT_REGIST
         ,XxcsoConstants.TOKEN_ACTION
         ,actionValue
        );


    // URL�p�����[�^�pMap
    HashMap params = new HashMap(3);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoContractRegistConstants.MODE_UPDATE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,mngRow.getSpDecisionHeaderId().toString()
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY2
     ,mngRow.getContractManagementId().toString()
    );

    // AM�߂�l�pMap�ւ̐ݒ�
    HashMap returnMap = new HashMap(2);
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_URL_PARAM
     ,params
    );
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_MESSAGE
     ,msg
    );

    XxcsoUtils.debug(txn, "[END]");

    return returnMap;
  }

  /*****************************************************************************
   * �I�[�i�[�ύX�`�F�b�N�{�b�N�X�ύX����
   *****************************************************************************
   */
  public void handleOwnerChangeFlagChange()
  {
    // �C���X�^���X�擾
    XxcsoPageRenderVOImpl pageRenderVo = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    // ��ʑ����ݒ�
    XxcsoContractRegistPropertyUtils.setAttributeOwnerChange(pageRenderVo);

    // ��ʍ��ړ��p�ݒ�
    XxcsoContractRegistReflectUtils.reflectInstallInfo(
      pageRenderVo
     ,mngVo
    );
  }

  /*****************************************************************************
   * �e�C�x���g�����̍Ō�ɍs���鏈���ł��B
   *****************************************************************************
   */
  public void afterProcess()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoBm1DestinationFullVO1"
        );
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoBm2DestinationFullVO1"
        );
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoBm3DestinationFullVO1"
        );
    }

    ////////////////////////////////////
    // �d����}�X�^�g�p�t���O��ݒ�
    ////////////////////////////////////
    XxcsoBm1DestinationFullVORowImpl dest1Row
      = (XxcsoBm1DestinationFullVORowImpl)dest1Vo.first();
    XxcsoBm2DestinationFullVORowImpl dest2Row
      = (XxcsoBm2DestinationFullVORowImpl)dest2Vo.first();
    XxcsoBm3DestinationFullVORowImpl dest3Row
      = (XxcsoBm3DestinationFullVORowImpl)dest3Vo.first();

    if ( dest1Row != null )
    {
      if ( dest1Row.getSupplierId() != null )
      {
        dest1Row.setVendorFlag("Y");
      }
      else
      {
        dest1Row.setVendorFlag("N");
      }
    }

    if ( dest2Row != null )
    {
      if ( dest2Row.getSupplierId() != null )
      {
        dest2Row.setVendorFlag("Y");
      }
      else
      {
        dest2Row.setVendorFlag("N");
      }
    }

    if ( dest3Row != null )
    {
      if ( dest3Row.getSupplierId() != null )
      {
        dest3Row.setVendorFlag("Y");
      }
      else
      {
        dest3Row.setVendorFlag("N");
      }
    }

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * ���b�Z�[�W���擾���܂��B
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * �S���[�W�����̒l����
   * @param fixedFlag �m��{�^�������t���O
   *****************************************************************************
   */
  private void validateAll(
    boolean fixedFlag
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    // �C���X�^���X�擾
    XxcsoPageRenderVOImpl pageRenderVo = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }

    /////////////////////////////////////
    // ���؏����F�_��ҁi�b�j���
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateContractCustomer(
        txn
       ,mngVo
       ,cntrctVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�U�����E���ߓ����
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateContractTransfer(
        txn
       ,pageRenderVo
       ,mngVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�_����ԁE�r���������
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateCancellationOffer(
        txn
       ,mngVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�a�l�P�w����
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateBm1Dest(
        txn
       ,pageRenderVo
       ,dest1Vo
       ,bank1Vo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�a�l�Q�w����
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateBm2Dest(
        txn
       ,pageRenderVo
       ,dest2Vo
       ,bank2Vo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�a�l�R�w����
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateBm3Dest(
        txn
       ,pageRenderVo
       ,dest3Vo
       ,bank3Vo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F�ݒu����
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateContractInstall(
        txn
       ,pageRenderVo
       ,mngVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // ���؏����F���s���������
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validatePublishBase(
        txn
       ,mngVo
       ,fixedFlag
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    OAException oaeMsg = null;

    /////////////////////////////////////
    // ���؏����F�ݒu��AR��v���ԃ`�F�b�N
    /////////////////////////////////////
    oaeMsg
      = XxcsoContractRegistValidateUtils.validateInstallDate(
          txn
         ,pageRenderVo
         ,mngVo
         ,fixedFlag
        );

    if (oaeMsg != null)
    {
      throw oaeMsg;
    }

    /////////////////////////////////////
    // ���؏����FBM���փ`�F�b�N
    /////////////////////////////////////
    oaeMsg
      = XxcsoContractRegistValidateUtils.validateBmRelation(
          txn
         ,pageRenderVo
         ,mngVo
         ,dest1Vo
         ,bank1Vo
         ,dest2Vo
         ,bank2Vo
         ,dest3Vo
         ,bank3Vo
// 2009-04-08 [ST��QT1_0364] Add Start
         ,fixedFlag
// 2009-04-08 [ST��QT1_0364] Add End
        );
    if (oaeMsg != null)
    {
      throw oaeMsg;
    }

    /////////////////////////////////////
    // ���؏����F�x�����׏��������`�F�b�N
    /////////////////////////////////////
    oaeMsg
      = XxcsoContractRegistValidateUtils.validateBellingDetailsCompliance(
          txn
         ,pageRenderVo
         ,mngVo
         ,dest1Vo
         ,dest2Vo
         ,dest3Vo
         ,fixedFlag
        );
    if (oaeMsg != null)
    {
      throw oaeMsg;
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * BM�֘A�ڋq�`�F�b�N�iAM���`�F�b�N�j
   * @return OAException 
   *****************************************************************************
   */
  private OAException validateBmAccountInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException confirmMsg = null;

    // ��ʃC���X�^���X�擾
    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }
    // ��ʍs�C���X�^���X�擾
    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) dest1Vo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) dest2Vo.first();

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) dest3Vo.first();

    String bm1VendorCode = null;
    String bm2VendorCode = null;
    String bm3VendorCode = null;

    if ( bm1DestVoRow != null )
    {
      bm1VendorCode = bm1DestVoRow.getVendorCode();
    }
    if ( bm2DestVoRow != null )
    {
      bm2VendorCode = bm2DestVoRow.getVendorCode();
    }
    if ( bm3DestVoRow != null )
    {
      bm3VendorCode = bm3DestVoRow.getVendorCode();
    }

    // ���ؗpVO�̏�����
    XxcsoBmAccountInfoSummaryVOImpl bmAccVo = getXxcsoBmAccountInfoSummaryVO1();
    if ( bmAccVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmAccountInfoSummaryVOImpl");
    }
    bmAccVo.initQuery(
      bm1VendorCode
     ,bm2VendorCode
     ,bm3VendorCode
     ,mngRow.getInstallAccountId()
    );

    XxcsoBmAccountInfoSummaryVORowImpl bmAccVoRow
      = (XxcsoBmAccountInfoSummaryVORowImpl) bmAccVo.first();
    if ( bmAccVoRow == null )
    {
      return confirmMsg;
    }

    int rowCnt = 0;
    StringBuffer sbMsg = new StringBuffer();
    while ( bmAccVoRow != null )
    {
      if (rowCnt != 0)
      {
        sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER2);
      }
      // �u�ڋq�R�[�h�F�ڋq���v�ŃG���[�p�̃��b�Z�[�W�𐶐�
      sbMsg.append(bmAccVoRow.getAccountNumber());
      sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER3);
      sbMsg.append(bmAccVoRow.getPartyName());
      rowCnt++;
      bmAccVoRow = (XxcsoBmAccountInfoSummaryVORowImpl) bmAccVo.next();
    }

    confirmMsg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00453
         ,XxcsoConstants.TOKEN_ACCOUNTS
         ,new String(sbMsg)
        );

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }

  /*****************************************************************************
   * �R�~�b�g�����ł��B
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���[���o�b�N�����ł��B
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");
  }
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
  /*****************************************************************************
   * �}�X�^�A�g�҂��`�F�b�N�����ł��B
   *****************************************************************************
   */
  public void cooperateWaitCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.cooperateWaitInfo();

    XxcsoUtils.debug(txn, "[END]");
  }
  /*****************************************************************************
   * �}�X�^�A�g�҂��`�F�b�N
   * @return OAException 
   *****************************************************************************
   */
  private OAException cooperateWaitInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException confirmMsg = null;

    // ��ʃC���X�^���X�擾
    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }
    // ��ʍs�C���X�^���X�擾
    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    OracleCallableStatement stmt = null;

    // �}�X�^�A�g�҂��`�F�b�N
    String ContractNumber = null;

    try
    {
      StringBuffer sql = new StringBuffer(300);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_010003j_pkg.chk_cooperate_wait(");
      sql.append("        iv_account_number    => :2");
      sql.append("        );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setString(2, mngRow.getInstallAccountNumber());

      stmt.execute();

      ContractNumber = stmt.getString(1);
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoContractRegistConstants.TOKEN_VALUE_COOPERATE_WAIT_INFO_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    if (!(ContractNumber == null || "".equals(ContractNumber)))
    {
      confirmMsg
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00595
           ,XxcsoConstants.TOKEN_RECORD
           ,ContractNumber
          );
    }

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
  /**
   * 
   * Container's getter for XxcsoContractManagementFullVO1
   */
  public XxcsoContractManagementFullVOImpl getXxcsoContractManagementFullVO1()
  {
    return (XxcsoContractManagementFullVOImpl)findViewObject("XxcsoContractManagementFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestinationFullVO1
   */
  public XxcsoBm1DestinationFullVOImpl getXxcsoBm1DestinationFullVO1()
  {
    return (XxcsoBm1DestinationFullVOImpl)findViewObject("XxcsoBm1DestinationFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestinationFullVO1
   */
  public XxcsoBm2DestinationFullVOImpl getXxcsoBm2DestinationFullVO1()
  {
    return (XxcsoBm2DestinationFullVOImpl)findViewObject("XxcsoBm2DestinationFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestinationFullVO1
   */
  public XxcsoBm3DestinationFullVOImpl getXxcsoBm3DestinationFullVO1()
  {
    return (XxcsoBm3DestinationFullVOImpl)findViewObject("XxcsoBm3DestinationFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractCustomerFullVO1
   */
  public XxcsoContractCustomerFullVOImpl getXxcsoContractCustomerFullVO1()
  {
    return (XxcsoContractCustomerFullVOImpl)findViewObject("XxcsoContractCustomerFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1ContractSpCustFullVO1
   */
  public XxcsoBm1ContractSpCustFullVOImpl getXxcsoBm1ContractSpCustFullVO1()
  {
    return (XxcsoBm1ContractSpCustFullVOImpl)findViewObject("XxcsoBm1ContractSpCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1BankAccountFullVO1
   */
  public XxcsoBm1BankAccountFullVOImpl getXxcsoBm1BankAccountFullVO1()
  {
    return (XxcsoBm1BankAccountFullVOImpl)findViewObject("XxcsoBm1BankAccountFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2BankAccountFullVO1
   */
  public XxcsoBm2BankAccountFullVOImpl getXxcsoBm2BankAccountFullVO1()
  {
    return (XxcsoBm2BankAccountFullVOImpl)findViewObject("XxcsoBm2BankAccountFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3BankAccountFullVO1
   */
  public XxcsoBm3BankAccountFullVOImpl getXxcsoBm3BankAccountFullVO1()
  {
    return (XxcsoBm3BankAccountFullVOImpl)findViewObject("XxcsoBm3BankAccountFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm1DestVL1
   */
  public ViewLinkImpl getXxcsoContractMngBm1DestVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm1DestVL1");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm2DestVL1
   */
  public ViewLinkImpl getXxcsoContractMngBm2DestVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm2DestVL1");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm3DestVL1
   */
  public ViewLinkImpl getXxcsoContractMngBm3DestVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm3DestVL1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestBankVL1
   */
  public ViewLinkImpl getXxcsoBm1DestBankVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm1DestBankVL1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestBankVL1
   */
  public ViewLinkImpl getXxcsoBm2DestBankVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm2DestBankVL1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestBankVL1
   */
  public ViewLinkImpl getXxcsoBm3DestBankVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm3DestBankVL1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010003j.server", "XxcsoContractRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoContractCreateInitVO1
   */
  public XxcsoContractCreateInitVOImpl getXxcsoContractCreateInitVO1()
  {
    return (XxcsoContractCreateInitVOImpl)findViewObject("XxcsoContractCreateInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoInitBmInfoSummaryVO1
   */
  public XxcsoInitBmInfoSummaryVOImpl getXxcsoInitBmInfoSummaryVO1()
  {
    return (XxcsoInitBmInfoSummaryVOImpl)findViewObject("XxcsoInitBmInfoSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoLoginUserSummaryVO1
   */
  public XxcsoLoginUserSummaryVOImpl getXxcsoLoginUserSummaryVO1()
  {
    return (XxcsoLoginUserSummaryVOImpl)findViewObject("XxcsoLoginUserSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2ContractSpCustFullVO1
   */
  public XxcsoBm2ContractSpCustFullVOImpl getXxcsoBm2ContractSpCustFullVO1()
  {
    return (XxcsoBm2ContractSpCustFullVOImpl)findViewObject("XxcsoBm2ContractSpCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3ContractSpCustFullVO1
   */
  public XxcsoBm3ContractSpCustFullVOImpl getXxcsoBm3ContractSpCustFullVO1()
  {
    return (XxcsoBm3ContractSpCustFullVOImpl)findViewObject("XxcsoBm3ContractSpCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesCondSummaryVO1
   */
  public XxcsoSalesCondSummaryVOImpl getXxcsoSalesCondSummaryVO1()
  {
    return (XxcsoSalesCondSummaryVOImpl)findViewObject("XxcsoSalesCondSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContainerCondSummaryVO1
   */
  public XxcsoContainerCondSummaryVOImpl getXxcsoContainerCondSummaryVO1()
  {
    return (XxcsoContainerCondSummaryVOImpl)findViewObject("XxcsoContainerCondSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractFormatListVO
   */
  public XxcsoLookupListVOImpl getXxcsoContractFormatListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoContractFormatListVO");
  }

  /**
   * 
   * Container's getter for XxcsoContractStatusListVO
   */
  public XxcsoLookupListVOImpl getXxcsoContractStatusListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoContractStatusListVO");
  }

  /**
   * 
   * Container's getter for XxcsoDaysListVO
   */
  public XxcsoLookupListVOImpl getXxcsoDaysListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoDaysListVO");
  }

  /**
   * 
   * Container's getter for XxcsoMonthsListVO
   */
  public XxcsoLookupListVOImpl getXxcsoMonthsListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoMonthsListVO");
  }

  /**
   * 
   * Container's getter for XxcsoCancellationListVO
   */
  public XxcsoLookupListVOImpl getXxcsoCancellationListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoCancellationListVO");
  }

  /**
   * 
   * Container's getter for XxcsoTransferFeeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoTransferFeeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferFeeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentListVO
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentListVO");
  }

  /**
   * 
   * Container's getter for XxcsoKozaListVO
   */
  public XxcsoLookupListVOImpl getXxcsoKozaListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoKozaListVO");
  }

  /**
   * 
   * Container's getter for XxcsoPageRenderVO1
   */
  public XxcsoPageRenderVOImpl getXxcsoPageRenderVO1()
  {
    return (XxcsoPageRenderVOImpl)findViewObject("XxcsoPageRenderVO1");
  }


  /**
   * 
   * Container's getter for XxcsoContractManagementFullVO2
   */
  public XxcsoContractManagementFullVOImpl getXxcsoContractManagementFullVO2()
  {
    return (XxcsoContractManagementFullVOImpl)findViewObject("XxcsoContractManagementFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestinationFullVO2
   */
  public XxcsoBm1DestinationFullVOImpl getXxcsoBm1DestinationFullVO2()
  {
    return (XxcsoBm1DestinationFullVOImpl)findViewObject("XxcsoBm1DestinationFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestinationFullVO2
   */
  public XxcsoBm2DestinationFullVOImpl getXxcsoBm2DestinationFullVO2()
  {
    return (XxcsoBm2DestinationFullVOImpl)findViewObject("XxcsoBm2DestinationFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestinationFullVO2
   */
  public XxcsoBm3DestinationFullVOImpl getXxcsoBm3DestinationFullVO2()
  {
    return (XxcsoBm3DestinationFullVOImpl)findViewObject("XxcsoBm3DestinationFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm1BankAccountFullVO2
   */
  public XxcsoBm1BankAccountFullVOImpl getXxcsoBm1BankAccountFullVO2()
  {
    return (XxcsoBm1BankAccountFullVOImpl)findViewObject("XxcsoBm1BankAccountFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm2BankAccountFullVO2
   */
  public XxcsoBm2BankAccountFullVOImpl getXxcsoBm2BankAccountFullVO2()
  {
    return (XxcsoBm2BankAccountFullVOImpl)findViewObject("XxcsoBm2BankAccountFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm3BankAccountFullVO2
   */
  public XxcsoBm3BankAccountFullVOImpl getXxcsoBm3BankAccountFullVO2()
  {
    return (XxcsoBm3BankAccountFullVOImpl)findViewObject("XxcsoBm3BankAccountFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoContractCustomerFullVO2
   */
  public XxcsoContractCustomerFullVOImpl getXxcsoContractCustomerFullVO2()
  {
    return (XxcsoContractCustomerFullVOImpl)findViewObject("XxcsoContractCustomerFullVO2");
  }




  /**
   * 
   * Container's getter for XxcsoContractMngBm1DestVL2
   */
  public ViewLinkImpl getXxcsoContractMngBm1DestVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm1DestVL2");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm2DestVL2
   */
  public ViewLinkImpl getXxcsoContractMngBm2DestVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm2DestVL2");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm3DestVL2
   */
  public ViewLinkImpl getXxcsoContractMngBm3DestVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm3DestVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestBankVL2
   */
  public ViewLinkImpl getXxcsoBm1DestBankVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm1DestBankVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestBankVL2
   */
  public ViewLinkImpl getXxcsoBm2DestBankVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm2DestBankVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestBankVL2
   */
  public ViewLinkImpl getXxcsoBm3DestBankVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm3DestBankVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBmAccountInfoSummaryVO1
   */
  public XxcsoBmAccountInfoSummaryVOImpl getXxcsoBmAccountInfoSummaryVO1()
  {
    return (XxcsoBmAccountInfoSummaryVOImpl)findViewObject("XxcsoBmAccountInfoSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoLoginUserAuthorityVO1
   */
  public XxcsoLoginUserAuthorityVOImpl getXxcsoLoginUserAuthorityVO1()
  {
    return (XxcsoLoginUserAuthorityVOImpl)findViewObject("XxcsoLoginUserAuthorityVO1");
  }


}