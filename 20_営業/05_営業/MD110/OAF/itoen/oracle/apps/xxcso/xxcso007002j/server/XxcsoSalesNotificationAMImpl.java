/*============================================================================
* �t�@�C���� : XxcsoSalesNotificationAMImpl
* �T�v����   : ���k������ʒm��ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-08 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007002j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.xxcso007002j.util.XxcsoSalesNotificationConstants;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * ���k������ʒm��\�����邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotificationAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotificationAMImpl()
  {
  }



  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��B
   * @param mode     ���s���[�h
   * @param notifyId �ʒmID
   *****************************************************************************
   */
  public void initDetails(
    String mode
   ,String notifyId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSalesNotifySummaryVOImpl notifyVo
      = getXxcsoSalesNotifySummaryVO1();
    if ( notifyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesNotifyUserSumVO1"
        );
    }

    XxcsoSalesHeaderHistSumVOImpl headerVo
      = getXxcsoSalesHeaderHistSumVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderHistSumVO1"
        );
    }

    XxcsoSalesLineHistSumVOImpl lineVo
      = getXxcsoSalesLineHistSumVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesLineHistSumVO1"
        );
    }

    XxcsoSalesNotifyUserSumVOImpl userVo
      = getXxcsoSalesNotifyUserSumVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesNotifyUserSumVO1"
        );
    }

    ///////////////////////////////////////
    // �ʒmID��藚���w�b�_ID���擾
    ///////////////////////////////////////
    notifyVo.initQuery(notifyId);
    XxcsoSalesNotifySummaryVORowImpl notifyRow
      = (XxcsoSalesNotifySummaryVORowImpl)notifyVo.first();

    if ( XxcsoSalesNotificationConstants.MODE_REQUEST.equals(mode) )
    {
      notifyRow.setNotifyListHdrRNRender(Boolean.TRUE);
      notifyRow.setApprRjctCommentHdrRNRender(Boolean.FALSE);
    }

    if ( XxcsoSalesNotificationConstants.MODE_RESULT.equals(mode) )
    {
      notifyRow.setNotifyListHdrRNRender(Boolean.TRUE);
      notifyRow.setApprRjctCommentHdrRNRender(Boolean.TRUE);
    }

    if ( XxcsoSalesNotificationConstants.MODE_NOTIFY.equals(mode) )
    {
      notifyRow.setNotifyListHdrRNRender(Boolean.FALSE);
      notifyRow.setApprRjctCommentHdrRNRender(Boolean.FALSE);
    }

    ///////////////////////////////////////
    // �����w�b�_ID���eVO�̏�����
    ///////////////////////////////////////
    headerVo.initQuery(notifyRow.getHeaderHistoryId());
    XxcsoSalesHeaderHistSumVORowImpl headerRow
      = (XxcsoSalesHeaderHistSumVORowImpl)headerVo.first();

    if ( "Y".equals(headerRow.getSalesDashboadUseFlag()) )
    {
      headerRow.setLeadDescriptionLinkRender(Boolean.TRUE);
    }
    else
    {
      headerRow.setLeadDescriptionLinkRender(Boolean.FALSE);
    }
    
    lineVo.initQuery(notifyRow.getHeaderHistoryId());
    userVo.initQuery(notifyRow.getHeaderHistoryId());

    XxcsoSalesLineHistSumVORowImpl lineRow
      = (XxcsoSalesLineHistSumVORowImpl)lineVo.first();
    while ( lineRow != null )
    {
      setLineRender(lineRow);
      lineRow = (XxcsoSalesLineHistSumVORowImpl)lineVo.next();
    }
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * ���k�������N�N���b�N����
   * @return HashMap URL�p�����[�^
   *****************************************************************************
   */
  public HashMap handleSelectLeadDescriptionLink()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSalesHeaderHistSumVOImpl headerVo
      = getXxcsoSalesHeaderHistSumVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderHistSumVO1"
        );
    }

    XxcsoSalesHeaderHistSumVORowImpl headerRow
      = (XxcsoSalesHeaderHistSumVORowImpl)headerVo.first();

    HashMap params = new HashMap(1);
    params.put(
      "ASNReqFrmOpptyId"
     ,headerRow.getLeadId()
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return params;
  }


  /*****************************************************************************
   * ���k�����񗚗𖾍׍s�̕\���^��\���̐ݒ菈���ł��B
   * @param lineRow ���k�����񗚗𖾍׍s�C���X�^���X
   *****************************************************************************
   */
  private void setLineRender(
    XxcsoSalesLineHistSumVORowImpl lineRow
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // ���ׂĕ\���ɐݒ肵�܂��B
    lineRow.setSalesAdoptClassRender(Boolean.TRUE);
    lineRow.setSalesAreaRender(Boolean.TRUE);
    lineRow.setDelivPriceRender(Boolean.TRUE);
    lineRow.setStoreSalesPriceRender(Boolean.TRUE);
    lineRow.setStoreSalesPriceIncTaxRender(Boolean.TRUE);
    lineRow.setQuotationPriceRender(Boolean.TRUE);

    String salesClassCode = lineRow.getSalesClassCode();
    if ( salesClassCode == null || "".equals(salesClassCode) )
    {
      lineRow.setSalesAdoptClassRender(Boolean.FALSE);
    }
    else
    {
      if ( XxcsoSalesNotificationConstants.SALES_CLASS_CAMP.equals(
             salesClassCode)
         )
      {
        // �̗p�敪���\���ɐݒ肵�܂��B
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
      }
      if ( XxcsoSalesNotificationConstants.SALES_CLASS_CUT.equals(
             salesClassCode)
         )
      {
        // �̗p�敪�A�̔��ΏۃG���A�A�X�[���i�A
        // �����i�Ŕ��j�A�����i�ō��j�A���l
        // ���\���ɐݒ肵�܂��B
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
        lineRow.setSalesAreaRender(Boolean.FALSE);
        lineRow.setDelivPriceRender(Boolean.FALSE);
        lineRow.setStoreSalesPriceRender(Boolean.FALSE);
        lineRow.setStoreSalesPriceIncTaxRender(Boolean.FALSE);
        lineRow.setQuotationPriceRender(Boolean.FALSE);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /**
   * 
   * Container's getter for XxcsoSalesHeaderHistSumVO1
   */
  public XxcsoSalesHeaderHistSumVOImpl getXxcsoSalesHeaderHistSumVO1()
  {
    return (XxcsoSalesHeaderHistSumVOImpl)findViewObject("XxcsoSalesHeaderHistSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesLineHistSumVO1
   */
  public XxcsoSalesLineHistSumVOImpl getXxcsoSalesLineHistSumVO1()
  {
    return (XxcsoSalesLineHistSumVOImpl)findViewObject("XxcsoSalesLineHistSumVO1");
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso007002j.server", "XxcsoSalesNotificationAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoSalesNotifyUserSumVO1
   */
  public XxcsoSalesNotifyUserSumVOImpl getXxcsoSalesNotifyUserSumVO1()
  {
    return (XxcsoSalesNotifyUserSumVOImpl)findViewObject("XxcsoSalesNotifyUserSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesNotifySummaryVO1
   */
  public XxcsoSalesNotifySummaryVOImpl getXxcsoSalesNotifySummaryVO1()
  {
    return (XxcsoSalesNotifySummaryVOImpl)findViewObject("XxcsoSalesNotifySummaryVO1");
  }
}