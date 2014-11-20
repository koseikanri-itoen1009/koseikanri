/*============================================================================
* �t�@�C���� : XxcsoSalesRegistAMImpl
* �T�v����   : ���k������\����ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-08 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.xxcso007001j.util.XxcsoSalesDecisionViewConstants;

/*******************************************************************************
 * ���k�������\�����邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesDecisionViewAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesDecisionViewAMImpl()
  {
  }



  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��B
   * @param leadId ���kID
   *****************************************************************************
   */
  public void initDetails(
    String leadId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �C���X�^���X�擾
    XxcsoSalesHeaderSummaryVOImpl headerVo
      = getXxcsoSalesHeaderSummaryVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderSummaryVO1"
        );
    }

    XxcsoSalesLineSummaryVOImpl lineVo
      = getXxcsoSalesLineSummaryVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesLineSummaryVO1"
        );
    }

    /////////////////////////////////////
    // �������s
    /////////////////////////////////////
    headerVo.initQuery(leadId);
    lineVo.initQuery(leadId);

    XxcsoSalesHeaderSummaryVORowImpl headerRow
      = (XxcsoSalesHeaderSummaryVORowImpl)headerVo.first();

    if ( "1".equals(headerRow.getLeadUpdEnabled()) )
    {
      headerRow.setForwardButtonRender(Boolean.TRUE);
    }
    else
    {
      headerRow.setForwardButtonRender(Boolean.FALSE);
    }

    XxcsoSalesLineSummaryVORowImpl lineRow
      = (XxcsoSalesLineSummaryVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      setLineRender(lineRow);

      lineRow = (XxcsoSalesLineSummaryVORowImpl)lineVo.next();
    }
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * ���k��������͂փ{�^�����������ł��B
   * @return HashMap URL�p�����[�^
   *****************************************************************************
   */
  public HashMap handleForwardButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00335);
    }

    // �C���X�^���X�擾
    XxcsoSalesHeaderSummaryVOImpl headerVo
      = getXxcsoSalesHeaderSummaryVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderSummaryVO1"
        );
    }

    XxcsoSalesHeaderSummaryVORowImpl headerRow
      = (XxcsoSalesHeaderSummaryVORowImpl)headerVo.first();
    
    HashMap params = new HashMap(1);
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getLeadId()
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return params;
  }


  /*****************************************************************************
   * ���k�����񖾍׍s�̕\���^��\���̐ݒ菈���ł��B
   * @param lineRow ���k�����񖾍׍s�C���X�^���X
   *****************************************************************************
   */
  private void setLineRender(
    XxcsoSalesLineSummaryVORowImpl lineRow
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
      if ( XxcsoSalesDecisionViewConstants.SALES_CLASS_CAMP.equals(
             salesClassCode)
         )
      {
        // �̗p�敪���\���ɐݒ肵�܂��B
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
      }
      if ( XxcsoSalesDecisionViewConstants.SALES_CLASS_CUT.equals(
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
   * Container's getter for XxcsoSalesHeaderSummaryVO1
   */
  public XxcsoSalesHeaderSummaryVOImpl getXxcsoSalesHeaderSummaryVO1()
  {
    return (XxcsoSalesHeaderSummaryVOImpl)findViewObject("XxcsoSalesHeaderSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesLineSummaryVO1
   */
  public XxcsoSalesLineSummaryVOImpl getXxcsoSalesLineSummaryVO1()
  {
    return (XxcsoSalesLineSummaryVOImpl)findViewObject("XxcsoSalesLineSummaryVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso007001j.server", "XxcsoSalesDecisionViewAMLocal");
  }
}