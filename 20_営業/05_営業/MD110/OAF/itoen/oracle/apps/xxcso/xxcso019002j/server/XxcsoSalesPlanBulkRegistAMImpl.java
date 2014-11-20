/*============================================================================
* �t�@�C���� : XxcsoAcctMonthlyPlanFullVOImpl
* �T�v����   : ����v��(�����ڋq)�@�A�v���P�[�V�������W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS�p�M�F    �V�K�쐬
* 2009-04-22 1.1  SCS�������l  [ST��QT1_0585]��ʑJ�ڃZ�L�����e�B�s���Ή�
* 2009-06-30 1.2  SCS�������  [��Q0000281]��R�����̃`�F�b�N�C��
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.server;

import itoen.oracle.apps.xxcso.xxcso019002j.poplist.server.XxcsoTargetYearListVOImpl;
import itoen.oracle.apps.xxcso.xxcso019002j.poplist.server.XxcsoTargetMonthListVOImpl;
import itoen.oracle.apps.xxcso.xxcso019002j.util.XxcsoSalesPlanBulkRegistConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoRouteManagementUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
// 2009/04/22 [ST��QT1_0585] Del Start
//import itoen.oracle.apps.xxcso.common.util.XxcsoAcctSalesPlansUtils;
// 2009/04/22 [ST��QT1_0585] Del End
// 2009-06-30 [��Q0000281] Add Start
import itoen.oracle.apps.xxcso.common.util.XxcsoAcctSalesPlansUtils;
// 2009-06-30 [��Q0000281] Add End

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAEntityImpl;

import oracle.jbo.domain.Date;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.List;

/*******************************************************************************
 * ����v��(�����ڋq) �A�v���P�[�V�������W���[���N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanBulkRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanBulkRegistAMImpl()
  {
  }

  /*****************************************************************************
   * ������ʕ\���̏������s���܂��B
   * @param mode    ��ʃ��[�h
   *****************************************************************************
   */
  public void initDetails(
    String mode
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    
    this.rollback();
    
    XxcsoSalesPlanBulkRegistInitVOImpl initVo = 
      getXxcsoSalesPlanBulkRegistInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.
              createInstanceLostError("XxcsoSalesPlanBulkRegistInitVOImpl");
    }

    if ( ! initVo.isPreparedForExecution() )
    {
      XxcsoUtils.debug(txn, "initVo.executeQuery()");
      initVo.executeQuery();
    }

    XxcsoSalesPlanBulkRegistInitVORowImpl initRow
      = (XxcsoSalesPlanBulkRegistInitVORowImpl)initVo.first();

    if ( XxcsoSalesPlanBulkRegistConstants.MODE_FIRE_ACTION.equals(mode) )
    {
      XxcsoRsrcPlanSummaryVOImpl rsrcSumVo = getXxcsoRsrcPlanSummaryVO1();
      if ( rsrcSumVo == null )
      {
        throw XxcsoMessage.
                createInstanceLostError("XxcsoRsrcPlanSummaryVOImpl");
      }
      XxcsoRsrcPlanSummaryVORowImpl rsrcSumRow
        = (XxcsoRsrcPlanSummaryVORowImpl)rsrcSumVo.first();

      executeQuery(
        rsrcSumRow.getBaseCode()
       ,rsrcSumRow.getEmployeeNumber()
       ,""
       ,rsrcSumRow.getTargetYearMonth().substring(0, 4)
       ,rsrcSumRow.getTargetYearMonth().substring(4, 6)
      );

      initRow.setResultRender(Boolean.TRUE);
    }
    else
    {
      initRow.setResultRender(Boolean.FALSE);
    }

// 2009/04/22 [ST��QT1_0585] Mod Start
//    // ���O�C�����[�U�����_�c�ƈ��̏ꍇ�A�c�ƈ��͑I��s�i���g�Œ�j
//    initRow.setReadOnlyFlg(Boolean.FALSE);
//    if ( XxcsoAcctSalesPlansUtils.isSalesPerson( txn ) )
//    {
//      initRow.setReadOnlyFlg(Boolean.TRUE);
//      initRow.setEmployeeNumber(initRow.getMyEmployeeNumber());
//      initRow.setFullName(initRow.getMyFullName());
//    }
    // �v���t�@�C���̎擾�i����v��Z�L�����e�B�j
    String salesPlanSequrity =
      txn.getProfile(
        XxcsoSalesPlanBulkRegistConstants.XXCSO1_SALES_PLAN_SECURITY
      );
    if ( salesPlanSequrity == null || "".equals(salesPlanSequrity.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoSalesPlanBulkRegistConstants.XXCSO1_SALES_PLAN_SECURITY
        );
    }
    initRow.setReadOnlyFlg( Boolean.FALSE );
    if ( XxcsoSalesPlanBulkRegistConstants.SECURITY_REFERENCE.equals(
           salesPlanSequrity)
    )
    {
      // ���O�C�����[�U�[���S���c�ƈ��̏ꍇ
      // �c�ƈ����͍��ڂ͕ҏW�s�E���O�C�����[�U�[��ݒ�
      initRow.setReadOnlyFlg( Boolean.TRUE );
      initRow.setEmployeeNumber( initRow.getMyEmployeeNumber() );
      initRow.setFullName(       initRow.getMyFullName()       );
    }
// 2009/04/22 [ST��QT1_0585] Mod End

    XxcsoTargetYearListVOImpl yearListVo = getXxcsoTargetYearListVO1();
    yearListVo.executeQuery();

    XxcsoTargetMonthListVOImpl monthListVo = getXxcsoTargetMonthListVO1();
    monthListVo.executeQuery();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �i�ރ{�^���̏������s���܂��B
   *****************************************************************************
   */
  public void handleSearchButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00335);
    }
    
    XxcsoSalesPlanBulkRegistInitVOImpl initVo = 
      getXxcsoSalesPlanBulkRegistInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoSalesPlanBulkRegistInitVOImpl");
    }

    XxcsoSalesPlanBulkRegistInitVORowImpl initRow
      = (XxcsoSalesPlanBulkRegistInitVORowImpl)initVo.first();

    // �o���f�[�V�������e�[�u�����݃`�F�b�N
    List errorList = new ArrayList();
    this.validateSearchButton(errorList, initRow);
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    executeQuery(
      initRow.getBaseCode()
     ,initRow.getEmployeeNumber()
     ,initRow.getFullName()
     ,initRow.getTargetYear()
     ,initRow.getTargetMonth()
    );

    initRow.setResultRender(Boolean.TRUE);
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �K�p�{�^���̏������s���܂��B
   *****************************************************************************
   */
  public OAException handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }

    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo = 
      getXxcsoAcctMonthlyPlanFullVO1();    
    if ( monthlyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctMonthlyPlanFullVOImpl");
    }

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
      = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();
    
    // �o���f�[�V�������e�[�u�����݃`�F�b�N
    List errorList = new ArrayList();
    this.validateMonthlyPlan(errorList, monthlyVo, monthlyRow);
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // ���탁�b�Z�[�W�쐬
    List msgList   = new ArrayList();
    if ( getMonthlyState( monthlyVo ) )
    {
      OAException msg
        = XxcsoMessage.createConfirmMessage(
            XxcsoConstants.APP_XXCSO1_00001
           ,XxcsoConstants.TOKEN_RECORD
           ,XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
           ,XxcsoConstants.TOKEN_ACTION
           ,XxcsoConstants.TOKEN_VALUE_SAVE
        );
        
      msgList.add(msg);

      // �G���e�B�e�B�ȊO���ڂ��Z�b�g
      setOtherMonthlyVo( monthlyVo );
    }

    // �G���e�B�e�B�I�u�W�F�N�g���s
    commit();

    XxcsoUtils.debug(txn, "[END]");

    return OAException.getBundledOAException(msgList);
  }

  /*****************************************************************************
   * ����{�^���̏������s���܂��B
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
   * �r���[�E�I�u�W�F�N�g�̌������s���܂��B
   * @param baseCode        ���_�R�[�h
   * @param employeeNumber  �]�ƈ��ԍ�
   * @param fullName        �]�ƈ���
   * @param targetYear      �Ώ۔N
   * @param targetMonth     �Ώی�
   *****************************************************************************
   */
  private void executeQuery(
    String baseCode
   ,String employeeNumber
   ,String fullName
   ,String targetYear
   ,String targetMonth
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRouteManagementUtils.getInstance().initTransactionBulk(
      getOADBTransaction()
     ,baseCode
     ,employeeNumber
     ,targetYear
     ,targetMonth
    );
    
    XxcsoRsrcPlanSummaryVOImpl rsrcSumVo = getXxcsoRsrcPlanSummaryVO1();
    if ( rsrcSumVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoRsrcPlanSummaryVOImpl");
    }
    
    rsrcSumVo.initQuery(
      baseCode
     ,employeeNumber
     ,targetYear + targetMonth
    );

    XxcsoRsrcPlanSummaryVORowImpl rsrcSuRow
      = (XxcsoRsrcPlanSummaryVORowImpl)rsrcSumVo.first();

    // �Ώ۔N�����ߋ��̏ꍇ�A�ڋq�ʌ��ʔ���v��͕ҏW�s��
    rsrcSuRow.setReadOnlyFlg(Boolean.FALSE);
    if ( rsrcSuRow != null )
    {
      if ( "1".equals(rsrcSuRow.getReadonlyValue()) )
      {
        rsrcSuRow.setReadOnlyFlg(Boolean.TRUE);
      }
    }

    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo = 
      getXxcsoAcctMonthlyPlanFullVO1();
    if ( monthlyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctMonthlyPlanFullVOImpl");
    }

    monthlyVo.initQuery(
      baseCode
     ,targetYear + targetMonth
     ,employeeNumber
    );

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
      = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �����{�^���������̃o���f�[�V�����`�F�b�N����
   * @param errorList  �G���[���X�g
   * @param initRow    ����v��(�����ڋq)����VO
   *****************************************************************************
   */
  private List validateSearchButton(
    List errorList
   ,XxcsoSalesPlanBulkRegistInitVORowImpl initRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �o���f�[�V�����`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    // �c�ƈ��R�[�h
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getEmployeeNumber()
         ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_EMPLOYEE_NUMBER
         ,0
        );

    // �Ώ۔N
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getTargetYear()
         ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_TARGET_YEAR
         ,0
        );
        
    // �Ώی�
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getTargetMonth()
         ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_TARGET_MONTH
         ,0
        );
        
    if ( errorList.size() > 0 )
    {
      return errorList;
    }
    
    // �Ώ۔N������Q�����ł��邱��
    String targetYM = initRow.getTargetYear() + initRow.getTargetMonth();
// 2009-06-30 [��Q0000281] Add Start
    //Date nowDate = txn.getCurrentUserDate();
    Date nowDate = XxcsoAcctSalesPlansUtils.getOnlineSysdate(txn);
// 2009-06-30 [��Q0000281] Add End    
    String next2YM = 
      nowDate.addMonths(2).toString().substring(0, 4) 
      + nowDate.toString().substring(5, 7);
    if ( next2YM.compareTo(targetYM) < 0 ) 
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00316
          );
      errorList.add(error);
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * �ڋq�ʔ���v��̃o���f�[�V�����`�F�b�N����
   * @param errorList   �G���[���X�g
   * @param monthlyVo    �ڋq�ʔ���v�����VO
   * @param monthlyRow   �ڋq�ʔ���v����ʍsVO
   *****************************************************************************
   */
  private List validateMonthlyPlan(
    List errorList
   ,XxcsoAcctMonthlyPlanFullVOImpl monthlyVo
   ,XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �o���f�[�V�����`�F�b�N���s���܂��B
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    byte monthlyState = OAEntityImpl.STATUS_UNMODIFIED;
    while ( monthlyRow != null )
    {
      byte monthlyRowState
        = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();

      if ( monthlyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        monthlyState = monthlyRowState;

        // �ڋq�ʌ��ʔ���v��i�Ώی��j
        errorList
          = utils.checkStringToNumber(
              errorList
             ,monthlyRow.getTargetMonthSalesPlanAmt()
             ,XxcsoSalesPlanBulkRegistConstants.
                TOKEN_VALUE_TRGT_MONTH_SALES_PLAN_AMT +
                  XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
                  XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName() +
                  XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
             ,0
             ,7
             ,true
             ,false
             ,false
             ,monthlyVo.getCurrentRowIndex() + 1
            );

        // �ڋq�ʌ��ʔ���v��i�Ώۗ����j
        errorList
          = utils.checkStringToNumber(
              errorList
             ,monthlyRow.getNextMonthSalesPlanAmt()
             ,XxcsoSalesPlanBulkRegistConstants.
                TOKEN_VALUE_NEXT_MONTH_SALES_PLAN_AMT +
                  XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
                  XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName() +
                  XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
             ,0
             ,7
             ,true
             ,false
             ,false
             ,monthlyVo.getCurrentRowIndex() + 1
            );

        // �S���c�ƈ��i�Ώۗ����j
        if ( monthlyRow.getNextEmployeeNumber() == null ||
             "".equals(monthlyRow.getNextEmployeeNumber()) )
        {
          errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00396
             ,XxcsoConstants.TOKEN_ACCOUNT
             ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                monthlyRow.getPartyName()
            )
          );
        }

        // ���[�gNo�i�Ώی��j
        if ( monthlyRow.getTargetMonthSalesPlanAmt() != null &&
             !"".equals(monthlyRow.getTargetMonthSalesPlanAmt()) )
        {
          if ( monthlyRow.getTargetRouteNumber() == null ||
               "".equals(monthlyRow.getTargetRouteNumber()) )
          {
            errorList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00311
               ,XxcsoConstants.TOKEN_ACCOUNT
               ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName()
              )
            );
          }
        }

        // ���[�gNo�i�Ώۗ����j
        if ( monthlyRow.getNextMonthSalesPlanAmt() != null &&
             !"".equals(monthlyRow.getNextMonthSalesPlanAmt()) )
        {
          if ( monthlyRow.getNextRouteNumber() == null ||
               "".equals(monthlyRow.getNextRouteNumber()) )
          {
            errorList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00311
               ,XxcsoConstants.TOKEN_ACCOUNT
               ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName()
              )
            );
          }
        }
      }
      monthlyRow = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * �ڋq�ʔ���v��̕ύX�L������
   * @param monthlyVo    �ڋq�ʔ���v��VO
   *****************************************************************************
   */
  private boolean getMonthlyState(
    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo
  )
  {
    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow = 
      (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();
    byte monthlyState = OAEntityImpl.STATUS_UNMODIFIED;
    while ( monthlyRow != null )
    {
      byte monthlyRowState
        = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();

      if ( monthlyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        return true;
      }
      monthlyRow = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.next();
    }

    return false;
  }

  /*****************************************************************************
   * �ڋq�ʔ���v���Entity�ȊO�̍��ڂ��Z�b�g
   * @param monthlyVo    �ڋq�ʔ���v��VO
   *****************************************************************************
   */
  private void setOtherMonthlyVo(
    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow = 
      (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();
    while ( monthlyRow != null )
    {
      byte monthlyRowState
        = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();

      if ( monthlyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        // �������Ώۃt���O
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setDistributeFlg(
            "1"
          );

        // �p�[�e�BID
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setPartyId(
            monthlyRow.getPartyId()
          );

        // �K��Ώۋ敪
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setVistTargetDiv(
            monthlyRow.getVistTargetDiv()
          );

        // ���[�gNo�i�Ώی��j
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setTargetRouteNumber(
            monthlyRow.getTargetRouteNumber()
          );

        // ���[�gNo�i�Ώۗ����j
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setNextRouteNumber(
            monthlyRow.getNextRouteNumber()
          );

      }
      monthlyRow = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �g�����U�N�V�����R�~�b�g
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRouteManagementUtils.getInstance().commitTransaction(txn);

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �g�����U�N�V�������[���o�b�N
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
  
  /**
   * 
   * Container's getter for XxcsoRsrcPlanSummaryVO1
   */
  public XxcsoRsrcPlanSummaryVOImpl getXxcsoRsrcPlanSummaryVO1()
  {
    return (XxcsoRsrcPlanSummaryVOImpl)findViewObject("XxcsoRsrcPlanSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAcctMonthlyPlanFullVO1
   */
  public XxcsoAcctMonthlyPlanFullVOImpl getXxcsoAcctMonthlyPlanFullVO1()
  {
    return (XxcsoAcctMonthlyPlanFullVOImpl)findViewObject("XxcsoAcctMonthlyPlanFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesPlanBulkRegistInitVO1
   */
  public XxcsoSalesPlanBulkRegistInitVOImpl getXxcsoSalesPlanBulkRegistInitVO1()
  {
    return (XxcsoSalesPlanBulkRegistInitVOImpl)findViewObject("XxcsoSalesPlanBulkRegistInitVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019002j.server", "XxcsoSalesPlanBulkRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoTargetYearListVO1
   */
  public XxcsoTargetYearListVOImpl getXxcsoTargetYearListVO1()
  {
    return (XxcsoTargetYearListVOImpl)findViewObject("XxcsoTargetYearListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTargetMonthListVO1
   */
  public XxcsoTargetMonthListVOImpl getXxcsoTargetMonthListVO1()
  {
    return (XxcsoTargetMonthListVOImpl)findViewObject("XxcsoTargetMonthListVO1");
  }
}