/*============================================================================
* �t�@�C���� : XxcsoVisitSalesPlanRegistAMImpl
* �T�v����   : �K��E����v���ʁ@�A�v���P�[�V�������W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F    �V�K�쐬
* 2009-06-05 1.1  SCS�������l  [ST��QT1_1245]���ڍX�V���@�̏C��
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcso.common.util.XxcsoAcctSalesPlansUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoRouteManagementUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.xxcso019001j.poplist.server.XxcsoPlanMonthListVOImpl;
import itoen.oracle.apps.xxcso.xxcso019001j.poplist.server.XxcsoPlanYearListVOImpl;
import itoen.oracle.apps.xxcso.xxcso019001j.util.XxcsoVisitSalesPlanConstants;

import java.sql.SQLException;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAEntityImpl;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;

/*******************************************************************************
 * �K��E����v���ʁ@�A�v���P�[�V�������W���[���N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoVisitSalesPlanRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoVisitSalesPlanRegistAMImpl()
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
    
    XxcsoAcctSalesInitVOImpl initVo = getXxcsoAcctSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAcctSalesInitVOImpl");
    }

    if ( ! initVo.isPreparedForExecution() )
    {
      XxcsoUtils.debug(txn, "initVo.executeQuery()");
      initVo.executeQuery();
    }

    XxcsoAcctSalesInitVORowImpl initRow
      = (XxcsoAcctSalesInitVORowImpl)initVo.first();

    if ( XxcsoVisitSalesPlanConstants.MODE_FIRE_ACTION.equals(mode) )
    {
      XxcsoAcctSalesSummaryVOImpl acctSumVo = getXxcsoAcctSalesSummaryVO1();
      if ( acctSumVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoAcctSalesSummaryVOImpl");
      }

      XxcsoAcctSalesSummaryVORowImpl acctSumRow
        = (XxcsoAcctSalesSummaryVORowImpl)acctSumVo.first();

      executeQuery(
        initRow.getBaseCode()
       ,initRow.getEmployeeNumber()
       ,initRow.getFullName()
       ,acctSumRow.getAccountNumber()
       ,acctSumRow.getPartyName()
       ,acctSumRow.getPlanYear()
       ,acctSumRow.getPlanMonth()
       ,acctSumRow.getPartyId()
       ,acctSumRow.getVistTargetDiv()
      );

      initRow.setResultRender(Boolean.TRUE);
    }
    else
    {
      initRow.setResultRender(Boolean.FALSE);
    }

    XxcsoPlanYearListVOImpl yearListVo = getXxcsoPlanYearListVO1();
    yearListVo.executeQuery();

    XxcsoPlanMonthListVOImpl monthListVo = getXxcsoPlanMonthListVO1();
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
    
    XxcsoAcctSalesInitVOImpl initVo = getXxcsoAcctSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAcctSalesInitVOImpl");
    }

    XxcsoAcctSalesInitVORowImpl initRow
      = (XxcsoAcctSalesInitVORowImpl)initVo.first();

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
     ,initRow.getAccountNumber()
     ,initRow.getPartyName()
     ,initRow.getPlanYear()
     ,initRow.getPlanMonth()
     ,initRow.getPartyId()
     ,initRow.getVistTargetDiv()
    );

    initRow.setResultRender(Boolean.TRUE);
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���Ԕ���v��̃t�H�[�J�X�A�E�g�̏������s���܂��B
   *****************************************************************************
   */
  public void handleTargetMonthSalesPlanAmtChange()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }
      
    XxcsoAcctSalesInitVOImpl initVo = getXxcsoAcctSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAcctSalesInitVOImpl");
    }

    XxcsoAcctSalesInitVORowImpl initRow
      = (XxcsoAcctSalesInitVORowImpl)initVo.first();
    
    XxcsoRtnRsrcFullVOImpl rtnVo = getXxcsoRtnRsrcFullVO1();
    if ( rtnVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoRtnRsrcFullVOImpl");
    }

    XxcsoRtnRsrcFullVORowImpl rtnRow
      = (XxcsoRtnRsrcFullVORowImpl)rtnVo.first();
    
    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo = getXxcsoAcctMonthlyPlanFullVO1();
    if ( monthlyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctMonthlyPlanFullVOImpl");
    }

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
      = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();

    XxcsoAcctWeeklyPlanFullVOImpl weeklyVo = getXxcsoAcctWeeklyPlanFullVO1();
    if ( weeklyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctWeeklyPlanFullVOImpl");
    }

    XxcsoAcctWeeklyPlanFullVORowImpl weeklyRow
      = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.first();

    List errorList = new ArrayList();

    errorList
      = validateTargetMonthSalesPlanAmtChange(
          errorList
         ,rtnRow
         ,monthlyRow);

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // ������
    setupDistributeSalesPlan(
      monthlyRow.getYearMonth()
     ,monthlyRow.getTargetMonthSalesPlanAmt()
     ,rtnRow.getTrgtRouteNo()
     ,initRow.getVistTargetDiv()
     ,weeklyVo
     ,weeklyRow
    );
    
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

    XxcsoAcctSalesSummaryVOImpl acctSumVo = getXxcsoAcctSalesSummaryVO1();
    if ( acctSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctSalesSummaryVOImpl");
    }

    XxcsoAcctSalesSummaryVORowImpl acctSumRow
      = (XxcsoAcctSalesSummaryVORowImpl)acctSumVo.first();

    XxcsoRtnRsrcFullVOImpl rtnVo = getXxcsoRtnRsrcFullVO1();
    if ( rtnVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoRtnRsrcFullVOImpl");
    }

    XxcsoRtnRsrcFullVORowImpl rtnRow
      = (XxcsoRtnRsrcFullVORowImpl)rtnVo.first();

    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo = getXxcsoAcctMonthlyPlanFullVO1();
    if ( monthlyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctMonthlyPlanFullVOImpl");
    }

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
      = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();

    XxcsoAcctWeeklyPlanFullVOImpl weeklyVo = getXxcsoAcctWeeklyPlanFullVO1();
    if ( weeklyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAcctWeeklyPlanFullVOImpl");
    }

    XxcsoAcctWeeklyPlanFullVORowImpl weeklyRow
      = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    List errorList = new ArrayList();
    List msgList   = new ArrayList();

    // ���[�gNo�̌���
    byte rtnState
      = rtnRow.getXxcsoRtnRsrcVEO().getEntityState();

    if ( rtnState == OAEntityImpl.STATUS_MODIFIED )
    {
      errorList
        = validateRouteNoResourece(
            errorList
           ,rtnRow);

      // ���탁�b�Z�[�W�쐬
      OAException msg
        = XxcsoMessage.createConfirmMessage(
            XxcsoConstants.APP_XXCSO1_00001
           ,XxcsoConstants.TOKEN_RECORD
           ,XxcsoConstants.TOKEN_VALUE_ROUTE_NO
           ,XxcsoConstants.TOKEN_ACTION
           ,XxcsoConstants.TOKEN_VALUE_SAVE
        );

      msgList.add(msg);
    }
    
    // �ڋq�ʔ���v��i���ʁj�̌���
    byte monthlyState
      = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();

    if ( monthlyState == OAEntityImpl.STATUS_MODIFIED )
    {
      errorList
        = validateMonthlyPlan(
            errorList
           ,monthlyRow
          );

      // ���탁�b�Z�[�W�쐬
      OAException msg
        = XxcsoMessage.createConfirmMessage(
            XxcsoConstants.APP_XXCSO1_00001
           ,XxcsoConstants.TOKEN_RECORD
           ,XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
           ,XxcsoConstants.TOKEN_ACTION
           ,XxcsoConstants.TOKEN_VALUE_SAVE
        );

      msgList.add(msg);
    }

    // �ڋq�ʔ���v����ʂ̌���
    errorList
      = validateWeeklyPlan(
          errorList
         ,weeklyVo
         ,weeklyRow);
    
    if ( getWeeklyState(weeklyVo, weeklyRow))
    {
      OAException msg
        = XxcsoMessage.createConfirmMessage(
            XxcsoConstants.APP_XXCSO1_00001
           ,XxcsoConstants.TOKEN_RECORD
           ,XxcsoConstants.TOKEN_VALUE_ACCT_DAILY_PLAN
           ,XxcsoConstants.TOKEN_ACTION
           ,XxcsoConstants.TOKEN_VALUE_SAVE
        );

      msgList.add(msg);
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // ���[�gNo���X�V���邽�ߓK�p�J�n����ݒ�
    reSetDateRouteNoResourece(rtnRow);
    
// 2009-06-05 [ST��QT1_1245] Add Start
    reflectWeeklyPlan( weeklyVo );
// 2009-06-05 [ST��QT1_1245] Add End

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
   * �R�~�b�g�������s���܂��B
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
   * ���[���o�b�N�������s���܂��B
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
  
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̌������s���܂��B
   * @param baseCode        ���_�R�[�h
   * @param employeeNumber  �]�ƈ��ԍ�
   * @param fullName        �]�ƈ���
   * @param accountNumber   �ڋq�ԍ�
   * @param partyName       �ڋq��
   * @param planYear        �v��N
   * @param planMonth       �v�挎
   * @param partyId         �p�[�e�BID
   * @param vistTargetDiv   �K��Ώۋ敪
   *****************************************************************************
   */
  private void executeQuery(
    String baseCode
   ,String employeeNumber
   ,String fullName
   ,String accountNumber
   ,String partyName
   ,String planYear
   ,String planMonth
   ,String partyId
   ,String vistTargetDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRouteManagementUtils.getInstance().initTransaction(
      getOADBTransaction()
     ,baseCode
     ,accountNumber
     ,planYear
     ,planMonth
    );
    
    XxcsoAcctSalesSummaryVOImpl acctSumVo = getXxcsoAcctSalesSummaryVO1();
    if ( acctSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctSalesSummaryVOImpl");
    }
    
    acctSumVo.initQuery(
      accountNumber
     ,partyName
     ,partyId
     ,vistTargetDiv
     ,planYear
     ,planMonth
    );

    XxcsoAcctSalesSummaryVORowImpl acctSumRow
      = (XxcsoAcctSalesSummaryVORowImpl)acctSumVo.first();

    XxcsoRtnRsrcFullVOImpl rtnVo = getXxcsoRtnRsrcFullVO1();
    if ( rtnVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoRtnRsrcFullVOImpl");
    }
    
    rtnVo.initQuery(accountNumber);

    XxcsoRsrcPlanSummaryVOImpl rsrcSumVo = getXxcsoRsrcPlanSummaryVO1();
    if ( rsrcSumVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoRsrcPlanSummaryVOImpl");
    }
    
    rsrcSumVo.initQuery(
      employeeNumber
     ,fullName
     ,baseCode
     ,acctSumRow.getYearMonth()
    );


    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo = getXxcsoAcctMonthlyPlanFullVO1();
    if ( monthlyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctMonthlyPlanFullVOImpl");
    }

    monthlyVo.initQuery(
      baseCode
     ,accountNumber
     ,acctSumRow.getYearMonth());

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
      = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();

    String diff = monthlyRow.getRsrcAcctDailyDiffer();

    XxcsoAcctWeeklyPlanFullVOImpl weeklyVo = getXxcsoAcctWeeklyPlanFullVO1();
    if ( weeklyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctWeeklyPlanFullVOImpl");
    }

    weeklyVo.initQuery(
      baseCode
     ,accountNumber
     ,acctSumRow.getYearMonth());

    XxcsoAcctWeeklyPlanFullVORowImpl weeklyRow
      = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.first();

    while ( weeklyRow != null )
    {
      if (  weeklyRow.getMondayColumn() == null            ||
            "".equals(weeklyRow.getMondayColumn().trim())
         )
      {
        weeklyRow.setMondayRender(Boolean.FALSE);
      }
      else
      {
        weeklyRow.setMondayRender(Boolean.TRUE);
      }
      if (  weeklyRow.getTuesdayColumn() == null            ||
            "".equals(weeklyRow.getTuesdayColumn().trim())
         )
      {
        weeklyRow.setTuesdayRender(Boolean.FALSE);
      }
      else
      {
        weeklyRow.setTuesdayRender(Boolean.TRUE);
      }
      if (  weeklyRow.getWednesdayColumn() == null            ||
            "".equals(weeklyRow.getWednesdayColumn().trim())
         )
      {
        weeklyRow.setWednesdayRender(Boolean.FALSE);
      }
      else
      {
        weeklyRow.setWednesdayRender(Boolean.TRUE);
      }
      if (  weeklyRow.getThursdayColumn() == null            ||
            "".equals(weeklyRow.getThursdayColumn().trim())
         )
      {
        weeklyRow.setThursdayRender(Boolean.FALSE);
      }
      else
      {
        weeklyRow.setThursdayRender(Boolean.TRUE);
      }
      if (  weeklyRow.getFridayColumn() == null            ||
            "".equals(weeklyRow.getFridayColumn().trim())
         )
      {
        weeklyRow.setFridayRender(Boolean.FALSE);
      }
      else
      {
        weeklyRow.setFridayRender(Boolean.TRUE);
      }
      if (  weeklyRow.getSaturdayColumn() == null            ||
            "".equals(weeklyRow.getSaturdayColumn().trim())
         )
      {
        weeklyRow.setSaturdayRender(Boolean.FALSE);
      }
      else
      {
        weeklyRow.setSaturdayRender(Boolean.TRUE);
      }
      if (  weeklyRow.getSundayColumn() == null            ||
            "".equals(weeklyRow.getSundayColumn().trim())
         )
      {
        weeklyRow.setSundayRender(Boolean.FALSE);
      }
      else
      {
        weeklyRow.setSundayRender(Boolean.TRUE);
      }

      weeklyRow = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �����{�^���������̃o���f�[�V�����`�F�b�N����
   * @param errorList  �G���[���X�g
   * @param initRow    �ڋq�ʔ���v���񌟍�VO
   *****************************************************************************
   */
  private List validateSearchButton(
    List errorList
   ,XxcsoAcctSalesInitVORowImpl initRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �o���f�[�V�����`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    // �ڋq�R�[�h
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getAccountNumber()
         ,XxcsoVisitSalesPlanConstants.TOKEN_VALUE_ACCOUNT_NUMBER
         ,0
        );

    // �v��N
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getPlanYear()
         ,XxcsoVisitSalesPlanConstants.TOKEN_VALUE_PLAN_YEAR
         ,0
        );
        
    // �v�挎
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getPlanMonth()
         ,XxcsoVisitSalesPlanConstants.TOKEN_VALUE_PLAN_MONTH
         ,0
        );
        
    if ( errorList.size() > 0 )
    {
      return errorList;
    }
    
    // �v��N���������`��R����
    String planYM = initRow.getPlanYear() + initRow.getPlanMonth();
    Date nowDate = txn.getCurrentUserDate();
    String nowYM = 
      nowDate.toString().substring(0, 4) 
      + nowDate.toString().substring(5, 7);
    String nextYM = 
      nowDate.addMonths(3).toString().substring(0, 4) 
      + nowDate.toString().substring(5, 7);
    if ( nowYM.compareTo(planYM) > 0  || 
         nextYM.compareTo(planYM) < 0 ) 
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00313
          );
      errorList.add(error);
    }

    // �ڋq�S���c�ƈ�(�ŐV)VIEW�̑��݃`�F�b�N
    errorList 
      = existAccountResouce(
        errorList
       ,initRow
      );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * ���ʔ���v��t�H�[�J�X�A�E�g���̃o���f�[�V�����`�F�b�N����
   * @param errorList   �G���[���X�g
   * @param rtnRow      ���[�gNo���sVO
   * @param monthlyRow  �ڋq�ʔ���v�挎�ʍsVO
   *****************************************************************************
   */
  private List validateTargetMonthSalesPlanAmtChange(
    List errorList
   ,XxcsoRtnRsrcFullVORowImpl rtnRow
   ,XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �o���f�[�V�����`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    // ���[�gNo(����)
    errorList
      = util.requiredCheck(
          errorList
         ,rtnRow.getTrgtRouteNo()
         ,XxcsoVisitSalesPlanConstants.TOKEN_VALUE_TRGT_ROUTENO
         ,0
        );

    // ���[�gNo�̌���
    byte rtnState
      = rtnRow.getXxcsoRtnRsrcVEO().getEntityState();
    if ( rtnState == OAEntityImpl.STATUS_MODIFIED )
    {
      errorList
        = validateRouteNoResourece(
            errorList
           ,rtnRow);
    }
    
    // �ڋq�ʔ���v��i���ʁj�̌���
    byte monthlyState
      = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();
    if ( monthlyState == OAEntityImpl.STATUS_MODIFIED )
    {
      errorList
        = validateMonthlyPlan(
            errorList
           ,monthlyRow
          );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * �ڋq�S���c�ƈ�(�ŐV)VIEW�̑��݃`�F�b�N����
   * @param errorList  �G���[���X�g
   * @param initRow    �ڋq�����sVO
   *****************************************************************************
   */
  private List existAccountResouce(
    List errorList
   ,XxcsoAcctSalesInitVORowImpl initRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �ڋq�S���c�ƈ�(�ŐV)VIEW�̑��݃`�F�b�N
    XxcsoValidateAcctRsrsVOImpl valVo = getXxcsoValidateAcctRsrsVO1();
    if ( valVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoValidateAcctRsrsVOImpl");
    }
    valVo.initQuery(
      initRow.getAccountNumber()
     ,initRow.getEmployeeNumber()
     ,initRow.getPlanYear() + initRow.getPlanMonth()
     );

    XxcsoValidateAcctRsrsVORowImpl valRow
      = (XxcsoValidateAcctRsrsVORowImpl)valVo.first();

    if (valRow == null) 
    {
      errorList.add(
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00312
        )
      );
    }
    else
    {
      // �p�[�e�BID�A�K��Ώۋ敪�̃Z�b�g
      initRow.setPartyId(valRow.getPartyId().stringValue());
      initRow.setVistTargetDiv(valRow.getVistTargetDiv());
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * ���[�gNo���̃o���f�[�V�����`�F�b�N����
   * @param errorList   �G���[���X�g
   * @param rtnRow      ���[�gNo���sVO
   *****************************************************************************
   */
  private List validateRouteNoResourece(
    List errorList
   ,XxcsoRtnRsrcFullVORowImpl rtnRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �o���f�[�V�����`�F�b�N���s���܂��B
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ���[�gNo(����)�Ó����`�F�b�N
    if ( rtnRow.getTrgtRouteNo() != null &&
         !validateRouteNo(rtnRow.getTrgtRouteNo()) )
    {
      errorList.add(
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00046
         ,XxcsoConstants.TOKEN_ENTRY
         ,XxcsoVisitSalesPlanConstants.TOKEN_VALUE_TRGT_ROUTENO
         ,XxcsoConstants.TOKEN_VALUES
         ,rtnRow.getTrgtRouteNo()
        )
      );
    }

    // ���[�gNo(�����ȍ~)�Ó����`�F�b�N
    if ( rtnRow.getNextRouteNo() != null &&
         !validateRouteNo(rtnRow.getNextRouteNo()) )
    {
      errorList.add(
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00046
         ,XxcsoConstants.TOKEN_ENTRY
         ,XxcsoVisitSalesPlanConstants.TOKEN_VALUE_NEXT_ROUTENO
         ,XxcsoConstants.TOKEN_VALUES
         ,rtnRow.getNextRouteNo()
        )
      );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * ���[�gNo�Ó����`�F�b�N�iPL/SQL�j
   * @param routNo      ���[�gNo
   *****************************************************************************
   */
  public boolean validateRouteNo(
    String        routeNo
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    StringBuffer sql = new StringBuffer(100);
    int index = 0;
    sql.append("DECLARE ");
    sql.append("  lbOK  BOOLEAN; ");
    sql.append("  lnOK  NUMBER  := 0; ");
    sql.append("BEGIN");
    sql.append("  lbOK := xxcso_route_common_pkg.validate_route_no(");
    sql.append("         iv_route_number   => :1");
    sql.append("        ,ov_error_reason   => :2");
    sql.append("       ); ");
    sql.append("  IF lbOK THEN ");
    sql.append("    lnOK := 1; ");
    sql.append("  END IF; ");
    sql.append("  :3 := lnOK; ");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    boolean isOk = false;
    int iOk = 0;
    String errorReason  = "";
    try
    {
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
      stmt.setString(1, routeNo);
      stmt.registerOutParameter(2, OracleTypes.VARCHAR);
      stmt.registerOutParameter(3, OracleTypes.INTEGER);
      stmt.execute();
      errorReason  = stmt.getString(2);
      iOk = stmt.getInt(3);
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_INIT_ACCT_SALES_TXN
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
      }
    }

    if ( iOk > 0 )
    {
       isOk = true;
    }
    return isOk;
  }

  /*****************************************************************************
   * �ڋq�ʔ���v�挎�ʂ̃o���f�[�V�����`�F�b�N����
   * @param errorList   �G���[���X�g
   * @param weeklyRow   �ڋq�ʔ���v����ʍsVO
   *****************************************************************************
   */
  private List validateMonthlyPlan(
    List errorList
   ,XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �o���f�[�V�����`�F�b�N���s���܂��B
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    errorList
      = utils.checkStringToNumber(
          errorList
         ,monthlyRow.getTargetMonthSalesPlanAmt()
         ,XxcsoVisitSalesPlanConstants.TOKEN_VALUE_TARGET_MONTH_SALES_PLAN_AMT
         ,0
         ,7
         ,true
         ,false
         ,false
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * �ڋq�ʔ���v����ʂ̃o���f�[�V�����`�F�b�N����
   * @param errorList   �G���[���X�g
   * @param weeklyVo    �ڋq�ʔ���v�����VO
   * @param weeklyRow   �ڋq�ʔ���v����ʍsVO
   *****************************************************************************
   */
  private List validateWeeklyPlan(
    List errorList
   ,XxcsoAcctWeeklyPlanFullVOImpl weeklyVo
   ,XxcsoAcctWeeklyPlanFullVORowImpl weeklyRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �o���f�[�V�����`�F�b�N���s���܂��B
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    byte weeklyState = OAEntityImpl.STATUS_UNMODIFIED;
    while ( weeklyRow != null )
    {
      byte weeklyRowState
        = weeklyRow.getXxcsoAcctWeeklyPlansVEO().getEntityState();

      if ( weeklyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        weeklyState = weeklyRowState;

        // �ڋq�ʔ���v��i���ʁj�̌���
        // ���j��
        errorList
          = utils.checkStringToNumber(
              errorList
             ,weeklyRow.getMondayValue()
             ,weeklyRow.getMondayColumn() + XxcsoConstants.TOKEN_VALUE_DAY
             ,0
             ,6
             ,true
             ,true
             ,false
             ,0
            );

        // �Ηj��
        errorList
          = utils.checkStringToNumber(
              errorList
             ,weeklyRow.getTuesdayValue()
             ,weeklyRow.getTuesdayColumn() + XxcsoConstants.TOKEN_VALUE_DAY
             ,0
             ,6
             ,true
             ,true
             ,false
             ,0
            );

        // ���j��
        errorList
          = utils.checkStringToNumber(
              errorList
             ,weeklyRow.getWednesdayValue()
             ,weeklyRow.getWednesdayColumn() + XxcsoConstants.TOKEN_VALUE_DAY
             ,0
             ,6
             ,true
             ,true
             ,false
             ,0
            );

        // �ؗj��
        errorList
          = utils.checkStringToNumber(
              errorList
             ,weeklyRow.getThursdayValue()
             ,weeklyRow.getThursdayColumn() + XxcsoConstants.TOKEN_VALUE_DAY
             ,0
             ,6
             ,true
             ,true
             ,false
             ,0
            );

        // ���j��
        errorList
          = utils.checkStringToNumber(
              errorList
             ,weeklyRow.getFridayValue()
             ,weeklyRow.getFridayColumn() + XxcsoConstants.TOKEN_VALUE_DAY
             ,0
             ,6
             ,true
             ,true
             ,false
             ,0
            );

        // �y�j��
        errorList
          = utils.checkStringToNumber(
              errorList
             ,weeklyRow.getSaturdayValue()
             ,weeklyRow.getSaturdayColumn() + XxcsoConstants.TOKEN_VALUE_DAY
             ,0
             ,6
             ,true
             ,true
             ,false
             ,0
            );

        // ���j��
        errorList
          = utils.checkStringToNumber(
              errorList
             ,weeklyRow.getSundayValue()
             ,weeklyRow.getSundayColumn() + XxcsoConstants.TOKEN_VALUE_DAY
             ,0
             ,6
             ,true
             ,true
             ,false
             ,0
            );
      }
      weeklyRow = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * �ڋq�ʔ���v����ʂ̃o���f�[�V�����`�F�b�N����
   * @param weeklyVo    �ڋq�ʔ���v�����VO
   * @param weeklyRow   �ڋq�ʔ���v����ʍsVO
   * @return true:�����ꂩ�̃��R�[�h���ҏW,false:���ҏW
   *****************************************************************************
   */
  private boolean getWeeklyState(
    XxcsoAcctWeeklyPlanFullVOImpl weeklyVo
   ,XxcsoAcctWeeklyPlanFullVORowImpl weeklyRow
  )
  {
    weeklyRow = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.first();
    byte weeklyState = OAEntityImpl.STATUS_UNMODIFIED;
    while ( weeklyRow != null )
    {
      byte weeklyRowState
        = weeklyRow.getXxcsoAcctWeeklyPlansVEO().getEntityState();

      if ( weeklyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        return true;
      }
      weeklyRow = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.next();
    }

    return false;
  }

  /*****************************************************************************
   * ���Ԕ���v�����ʔ���v��Ɉ����A���ʂ��ڋq�ʔ���v�����VO�ɃZ�b�g
   * @param yearMonth     �v��N��
   * @param salesPlanAmt  ���Ԕ���v��
   * @param routNo        ���[�gNo
   * @param vistTargetDiv �K��Ώۋ敪
   * @param weeklyVo      �ڋq�ʔ���v�����VO
   * @param weeklyRow     �ڋq�ʔ���v����ʍsVO
   *****************************************************************************
   */
  private void setupDistributeSalesPlan(
    String                            yearMonth
   ,String                            salesPlanAmt
   ,String                            routeNo
   ,String                            vistTargetDiv
   ,XxcsoAcctWeeklyPlanFullVOImpl     weeklyVo
   ,XxcsoAcctWeeklyPlanFullVORowImpl  weeklyRow
  )
  {
    String salesPlanDayAmt[]
      = distributeSalesPlan(
          yearMonth
         ,salesPlanAmt
         ,routeNo
         ,vistTargetDiv);

    int index = 0;
    while ( weeklyRow != null )
    {
      // ���j��
      if ( weeklyRow.getMondayColumn() != null
           && !"".equals(weeklyRow.getMondayColumn()) )
      {
        weeklyRow.setMondayValue(salesPlanDayAmt[index]);
        index++;
      }

      // �Ηj��
      if ( weeklyRow.getTuesdayColumn() != null
           && !"".equals(weeklyRow.getTuesdayColumn()) )
      {
        weeklyRow.setTuesdayValue(salesPlanDayAmt[index]);
        index++;
      }

      // ���j��
      if ( weeklyRow.getWednesdayColumn() != null
           && !"".equals(weeklyRow.getWednesdayColumn()) )
      {
        weeklyRow.setWednesdayValue(salesPlanDayAmt[index]);
        index++;
      }

      // �ؗj��
      if ( weeklyRow.getThursdayColumn() != null
           && !"".equals(weeklyRow.getThursdayColumn()) )
      {
        weeklyRow.setThursdayValue(salesPlanDayAmt[index]);
        index++;
      }

      // ���j��
      if ( weeklyRow.getFridayColumn() != null
           && !"".equals(weeklyRow.getFridayColumn()) )
      {
        weeklyRow.setFridayValue(salesPlanDayAmt[index]);
        index++;
      }

      // �y�j��
      if ( weeklyRow.getSaturdayColumn() != null
           && !"".equals(weeklyRow.getSaturdayColumn()) )
      {
        weeklyRow.setSaturdayValue(salesPlanDayAmt[index]);
        index++;
      }

      // ���j��
      if ( weeklyRow.getSundayColumn() != null
           && !"".equals(weeklyRow.getSundayColumn()) )
      {
        weeklyRow.setSundayValue(salesPlanDayAmt[index]);
        index++;
      }
      weeklyRow = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.next();
    }
    
  }
  
  /*****************************************************************************
   * ���Ԕ���v�����ʔ���v��Ɉ�����B�iPL/SQL�j
   * @param yearMonth     �v��N��
   * @param salesPlanAmt  ���Ԕ���v��
   * @param routNo        ���[�gNo
   * @param vistTargrtDiv �K��Ώۋ敪
   *****************************************************************************
   */
  private String[] distributeSalesPlan(
    String        yearMonth
   ,String        salesPlanAmt
   ,String        routeNo
   ,String        vistTargrtDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �ڋq����v����ʃN���A
    String salesPlanDayAmt[] = new String[31];
    for (int i = 0; i < 31; i++)
    {
      salesPlanDayAmt[i] = "";
    }

    // �K��Ώۋ敪��1:�K��Ώۂ́A�������Ȃ�
    // ���Ԕ���v�恁NULL�܂��́A0�̏ꍇ�́A�������Ȃ�
    if ( !"1".equals(vistTargrtDiv) ||
         salesPlanAmt == null ||
         "".equals(salesPlanAmt) ||
         "0".equals(salesPlanAmt)
       )
    {
      return salesPlanDayAmt;
    }
    
    StringBuffer sql = new StringBuffer(300);
    int index = 0;
    sql.append("BEGIN");
    sql.append("  xxcso_route_common_pkg.distribute_sales_plan(");
    sql.append("         iv_year_month             => :1");
    sql.append("        ,it_sales_plan_amt         => :2");
    sql.append("        ,it_route_number           => :3");
    sql.append("        ,on_day_on_month           => :4");
    sql.append("        ,on_visit_daytimes         => :5");
    sql.append("        ,ot_sales_plan_day_amt_1   => :6");
    sql.append("        ,ot_sales_plan_day_amt_2   => :7");
    sql.append("        ,ot_sales_plan_day_amt_3   => :8");
    sql.append("        ,ot_sales_plan_day_amt_4   => :9");
    sql.append("        ,ot_sales_plan_day_amt_5   => :10");
    sql.append("        ,ot_sales_plan_day_amt_6   => :11");
    sql.append("        ,ot_sales_plan_day_amt_7   => :12");
    sql.append("        ,ot_sales_plan_day_amt_8   => :13");
    sql.append("        ,ot_sales_plan_day_amt_9   => :14");
    sql.append("        ,ot_sales_plan_day_amt_10  => :15");
    sql.append("        ,ot_sales_plan_day_amt_11  => :16");
    sql.append("        ,ot_sales_plan_day_amt_12  => :17");
    sql.append("        ,ot_sales_plan_day_amt_13  => :18");
    sql.append("        ,ot_sales_plan_day_amt_14  => :19");
    sql.append("        ,ot_sales_plan_day_amt_15  => :20");
    sql.append("        ,ot_sales_plan_day_amt_16  => :21");
    sql.append("        ,ot_sales_plan_day_amt_17  => :22");
    sql.append("        ,ot_sales_plan_day_amt_18  => :23");
    sql.append("        ,ot_sales_plan_day_amt_19  => :24");
    sql.append("        ,ot_sales_plan_day_amt_20  => :25");
    sql.append("        ,ot_sales_plan_day_amt_21  => :26");
    sql.append("        ,ot_sales_plan_day_amt_22  => :27");
    sql.append("        ,ot_sales_plan_day_amt_23  => :28");
    sql.append("        ,ot_sales_plan_day_amt_24  => :29");
    sql.append("        ,ot_sales_plan_day_amt_25  => :30");
    sql.append("        ,ot_sales_plan_day_amt_26  => :31");
    sql.append("        ,ot_sales_plan_day_amt_27  => :32");
    sql.append("        ,ot_sales_plan_day_amt_28  => :33");
    sql.append("        ,ot_sales_plan_day_amt_29  => :34");
    sql.append("        ,ot_sales_plan_day_amt_30  => :35");
    sql.append("        ,ot_sales_plan_day_amt_31  => :36");
    sql.append("        ,ov_errbuf                 => :37");
    sql.append("        ,ov_retcode                => :38");
    sql.append("        ,ov_errmsg                 => :39");
    sql.append("       ); ");
    sql.append("END;");

    OracleCallableStatement stmt = null;

    try
    {
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, yearMonth);
      stmt.setNUMBER(2, new Number(salesPlanAmt.replaceAll(",", "")));
      stmt.setString(3, routeNo);
      for (int i = 1, offset = 3; i <= (2 + 31); i++)
      {
        stmt.registerOutParameter(offset + i, OracleTypes.NUMBER);
      }
      stmt.registerOutParameter(37, OracleTypes.VARCHAR);
      stmt.registerOutParameter(38, OracleTypes.VARCHAR);
      stmt.registerOutParameter(39, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(37);
      String retCode = stmt.getString(38);
      String errMsg  = stmt.getString(39);

      XxcsoUtils.debug(txn, "errbuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retcode = " + retCode);
      XxcsoUtils.debug(txn, "errmsg  = " + errMsg);
      
      if ( ! "0".equals(retCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_DISTRIBUTE_SALES_PLAN
           ,errBuf
          );
      }

      for (int i = 0, offset = 6; i < 31; i++)
      {
        if ( stmt.getLong(offset + i) > 0 )
        {
          salesPlanDayAmt[i] = new String().valueOf(stmt.getLong(offset + i));
        }
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
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
      }
    }

    return salesPlanDayAmt;
  }

  /*****************************************************************************
   * ���[�gNo���X�V���邽�ߓK�p�J�n����ݒ�
   * @param rtnRow      ���[�gNo���sVO
   *****************************************************************************
   */
  private void reSetDateRouteNoResourece(
    XxcsoRtnRsrcFullVORowImpl rtnRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    byte rtnState
      = rtnRow.getXxcsoRtnRsrcVEO().getEntityState();
    if ( rtnState != OAEntityImpl.STATUS_MODIFIED )
    {
      return;
    }

    // �I�����C���J�n���擾
    Date nowDate = XxcsoAcctSalesPlansUtils.getOnlineSysdate(txn);
    Date nowYearMonth = XxcsoAcctSalesPlansUtils.getOnlineSysdateFirst(txn);
    Date nextYearMonth = new Date(nowYearMonth);
    nextYearMonth.addMonths(1);
    
    // ���[�gNo(����)���o�^�܂��́A���[�gNo(����)���o�^
    if ( rtnRow.getTrgtRouteNoExtensionId() == null ||
         rtnRow.getNextRouteNoExtensionId() == null )
    {
      // ���[�gNo(����)�̓K�p�J�n��
      rtnRow.setTrgtRouteNoStartDate(nowYearMonth);

      // ���[�gNo(����)�̓K�p�J�n��
      rtnRow.setNextRouteNoStartDate(nextYearMonth);
    }

    XxcsoUtils.debug(txn, "[END]");
  }

// 2009-06-05 [ST��QT1_1245] Add Start
  /*****************************************************************************
   * �ڋq�ʔ���v����ʍĐݒ菈��
   * ��row�ւ̒l��S�čĐݒ肷��
   * @param weeklyVo      �ڋq�ʔ���v�����VO
   *****************************************************************************
   */
  private void reflectWeeklyPlan(
    XxcsoAcctWeeklyPlanFullVOImpl weeklyVo
  )
  {
    XxcsoAcctWeeklyPlanFullVORowImpl weeklyRow
      = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.first();

    while ( weeklyRow != null )
    {
      // ���j��
      if ( weeklyRow.getMondayColumn() != null
           && !"".equals(weeklyRow.getMondayColumn()) )
      {
        String mondayValue = weeklyRow.getMondayValue();
        weeklyRow.setMondayValue(mondayValue);
      }

      // �Ηj��
      if ( weeklyRow.getTuesdayColumn() != null
           && !"".equals(weeklyRow.getTuesdayColumn()) )
      {
        String tuesdayValue = weeklyRow.getTuesdayValue();
        weeklyRow.setTuesdayValue(tuesdayValue);
      }

      // ���j��
      if ( weeklyRow.getWednesdayColumn() != null
           && !"".equals(weeklyRow.getWednesdayColumn()) )
      {
        String wednesdayValue = weeklyRow.getWednesdayValue();
        weeklyRow.setWednesdayValue(wednesdayValue);
      }

      // �ؗj��
      if ( weeklyRow.getThursdayColumn() != null
           && !"".equals(weeklyRow.getThursdayColumn()) )
      {
        String thursdayValue = weeklyRow.getThursdayValue();
        weeklyRow.setThursdayValue(thursdayValue);
      }

      // ���j��
      if ( weeklyRow.getFridayColumn() != null
           && !"".equals(weeklyRow.getFridayColumn()) )
      {
        String fridayValue = weeklyRow.getFridayValue();
        weeklyRow.setFridayValue(fridayValue);
      }

      // �y�j��
      if ( weeklyRow.getSaturdayColumn() != null
           && !"".equals(weeklyRow.getSaturdayColumn()) )
      {
        String saturdayValue = weeklyRow.getSaturdayValue();
        weeklyRow.setSaturdayValue(saturdayValue);
      }

      // ���j��
      if ( weeklyRow.getSundayColumn() != null
           && !"".equals(weeklyRow.getSundayColumn()) )
      {
        String sundayValue = weeklyRow.getSundayValue();
        weeklyRow.setSundayValue(sundayValue);
      }
      weeklyRow = (XxcsoAcctWeeklyPlanFullVORowImpl)weeklyVo.next();
    }
  }
// 2009-06-05 [ST��QT1_1245] Add End

  /**
   * 
   * Container's getter for XxcsoAcctSalesInitVO1
   */
  public XxcsoAcctSalesInitVOImpl getXxcsoAcctSalesInitVO1()
  {
    return (XxcsoAcctSalesInitVOImpl)findViewObject("XxcsoAcctSalesInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAcctSalesSummaryVO1
   */
  public XxcsoAcctSalesSummaryVOImpl getXxcsoAcctSalesSummaryVO1()
  {
    return (XxcsoAcctSalesSummaryVOImpl)findViewObject("XxcsoAcctSalesSummaryVO1");
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
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019001j.server", "XxcsoVisitSalesPlanRegistAMLocal");
  }









  /**
   * 
   * Container's getter for XxcsoPlanMonthListVO1
   */
  public XxcsoPlanMonthListVOImpl getXxcsoPlanMonthListVO1()
  {
    return (XxcsoPlanMonthListVOImpl)findViewObject("XxcsoPlanMonthListVO1");
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
   * Container's getter for XxcsoAcctWeeklyPlanFullVO1
   */
  public XxcsoAcctWeeklyPlanFullVOImpl getXxcsoAcctWeeklyPlanFullVO1()
  {
    return (XxcsoAcctWeeklyPlanFullVOImpl)findViewObject("XxcsoAcctWeeklyPlanFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcFullVO1
   */
  public XxcsoRtnRsrcFullVOImpl getXxcsoRtnRsrcFullVO1()
  {
    return (XxcsoRtnRsrcFullVOImpl)findViewObject("XxcsoRtnRsrcFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPlanYearListVO1
   */
  public XxcsoPlanYearListVOImpl getXxcsoPlanYearListVO1()
  {
    return (XxcsoPlanYearListVOImpl)findViewObject("XxcsoPlanYearListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoValidateAcctRsrsVO1
   */
  public XxcsoValidateAcctRsrsVOImpl getXxcsoValidateAcctRsrsVO1()
  {
    return (XxcsoValidateAcctRsrsVOImpl)findViewObject("XxcsoValidateAcctRsrsVO1");
  }




}