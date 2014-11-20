/*============================================================================
* �t�@�C���� : XxpoOrderReceiptCO
* �T�v����   : ������э쐬:������������R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  �g������     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

/***************************************************************************
 * ������������R���g���[���ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderReceiptCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // ********************************* //
      // * �_�C�A���O��ʁuYes�v������   * //
      // ********************************* //       
      if (pageContext.getParameter("Yes") != null) 
      {
        // �ꊇ�������
        am.invokeMethod("doBatchReceipt");

      // ********************************* //
      // * �_�C�A���O��ʁuNo�v������    * //
      // ********************************* //       
      } else if (pageContext.getParameter("No") != null) 
      {

      // ********************************* //
      // * �����\����                    * //
      // ********************************* //
      } else
      {
        // �������������s
        am.invokeMethod("initialize");                
      }
      
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO310001J, true))
      { 
        // �y���ʏ����z�G���[�_�C�A���O��ʂ֑J��
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      } 
    }
    
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
    try
    {
      // ************************* //
      // *   �i�ރ{�^��������    * //
      // ************************* //
      if (pageContext.getParameter("Go") != null) 
      {
        // ���������擾
        String headerNumber      = pageContext.getParameter("TxtHeaderNumber");        // ����No.
        String requestNumber     = pageContext.getParameter("TxtRequestNumber");       // �x��No.
        String vendorCode        = pageContext.getParameter("TxtVendorCode");          // �����R�[�h
        String vendorId          = pageContext.getParameter("TxtVendorId");            // �����ID     
        String mediationCode     = pageContext.getParameter("TxtMediationCode");       // �����҃R�[�h
        String mediationId       = pageContext.getParameter("TxtMediationId");         // ������ID
        String deliveryDateFrom  = pageContext.getParameter("TxtDeliveryDateFrom");    // �[�i��(�J�n)
        String deliveryDateTo    = pageContext.getParameter("TxtDeliveryDateTo");      // �[�i��(�I��) 
        String status            = pageContext.getParameter("TxtStatus");              // �X�e�[�^�X
        String location          = pageContext.getParameter("TxtLocation");            // �[�i��R�[�h
        String department        = pageContext.getParameter("TxtDepartment");          // ���������R�[�h
        String approved          = pageContext.getParameter("TxtApproved");            // �����v
        String purchase          = pageContext.getParameter("TxtPurchase");            // �����敪
        String orderApproved     = pageContext.getParameter("TxtOrderApproved");       // ��������
        String cancelSearch      = pageContext.getParameter("TxtCancelSearch");        // �������
        String purchaseApproved  = pageContext.getParameter("TxtPurchaseApproved");    // �d������

        // �����p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put("headerNumber",     headerNumber);
        searchParams.put("requestNumber",    requestNumber);
        searchParams.put("vendorCode",       vendorCode);
        searchParams.put("vendorId",         vendorId);
        searchParams.put("mediationCode",    mediationCode);
        searchParams.put("mediationId",      mediationId);
        searchParams.put("deliveryDateFrom", deliveryDateFrom);
        searchParams.put("deliveryDateTo",   deliveryDateTo);
        searchParams.put("status",           status);
        searchParams.put("location",         location);
        searchParams.put("department",       department);
        searchParams.put("approved",         approved);
        searchParams.put("purchase",         purchase);
        searchParams.put("orderApproved",    orderApproved);
        searchParams.put("purchaseApproved", purchaseApproved);
        
        // �����ݒ�
        Serializable params[] = { searchParams };
        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };

        // �������ړ��͕K�{�`�F�b�N
        am.invokeMethod("doRequiredCheck"); 

        // ����
        am.invokeMethod("doSearch", params, parameterTypes);        

      // ************************* //
      // *   �폜�{�^��������    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {

        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);        


      // ************************* //
      // *   �����N�N���b�N��    * //
      // ************************* //
      } else if ("HeaderNumberLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);
        
        // ��������(�����ԍ�)�擾
        String searchHeaderNumber = pageContext.getParameter("searchHeaderNumber");
        
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,  searchHeaderNumber);
        pageParams.put(XxpoConstants.URL_PARAM_START_CONDITION, "2");

        // �������:�ڍ׉�ʂ�
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JD,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // ******************* //
      // *  �y�[�W���O��   * //
      // ******************* //
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �I���`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
        am.invokeMethod("checkBoxOff");

      // ************************* //
      // * �ꊇ����{�^��������  * //
      // ************************* //
      } else if (pageContext.getParameter("BatchReceipt") != null) 
      {
        // ������񖢑I���`�F�b�N
        am.invokeMethod("chkSelect");
        
        // ���C�����b�Z�[�W�쐬 
        OAException mainMessage = new OAException(
                                        XxcmnConstants.APPL_XXPO,
                                        XxpoConstants.XXPO10209,
                                        null,
                                        OAException.INFORMATION,
                                        null);

        // �_�C�A���O���b�Z�[�W��\��
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxpoConstants.URL_XXPO310001JS,
          XxpoConstants.URL_XXPO310001JS,
          "Yes",
          "No",
          "Yes",
          "No",
          null);
      }
      
    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }

}
