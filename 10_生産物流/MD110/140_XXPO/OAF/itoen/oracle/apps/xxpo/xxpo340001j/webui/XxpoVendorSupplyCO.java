/*============================================================================
* �t�@�C���� : XxpoVendorSupplyCO
* �T�v����   : �O���o������:�����R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-26 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * �o�������ѕ�:�����R���g���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
      
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �������������s
      am.invokeMethod("initialize");

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO340001J, true))
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
        String lotNumber            = pageContext.getParameter("TxtLotNumber");            //���b�g�ԍ�
        String manufacturedDateFrom = pageContext.getParameter("TxtManufacturedDateFrom"); //���Y��FROM
        String manufacturedDateTo   = pageContext.getParameter("TxtManufacturedDateTo");   //���Y��TO
        String vendorCode           = pageContext.getParameter("TxtVendorCode");           //�����
        String factoryCode          = pageContext.getParameter("TxtFactoryCode");          //�H��
        String itemCode             = pageContext.getParameter("TxtItemCode");             //�i��
        String productedDateFrom    = pageContext.getParameter("TxtProductedDateFrom");    //������FROM
        String productedDateTo      = pageContext.getParameter("TxtProductedDateTo");      //������TO
        String koyuCode             = pageContext.getParameter("TxtKoyuCode");             //�ŗL�L��
        String corrected            = pageContext.getParameter("TxtCorrected");            //�����L
        // �����p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put("lotNumber"           , lotNumber);
        searchParams.put("manufacturedDateFrom", manufacturedDateFrom);
        searchParams.put("manufacturedDateTo"  , manufacturedDateTo);
        searchParams.put("vendorCode"          , vendorCode);
        searchParams.put("factoryCode"         , factoryCode);
        searchParams.put("itemCode"            , itemCode);
        searchParams.put("productedDateFrom"   , productedDateFrom);
        searchParams.put("productedDateTo"     , productedDateTo);
        searchParams.put("koyuCode"            , koyuCode);
        searchParams.put("corrected"           , corrected);
        // �����ݒ�
        Serializable params[] = { searchParams };
        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };

        // ����
        am.invokeMethod("doSearch", params, parameterTypes);
      
      // ************************* //
      // *   �����{�^��������    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
          
        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // ************************* //
      // *   �V�K�{�^��������    * //
      // ************************* //
      } else if (pageContext.getParameter("New") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
          
        // �O���o������:�o�^��ʂ�
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JM,
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
      } else if ("LotNumberClick".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
        
        // ��������(����ID)�擾
        String searchTxnsId = pageContext.getParameter("searchTxnsId");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_SEARCH_TXNS_ID, searchTxnsId);
        pageParams.put(XxpoConstants.URL_PARAM_UPDATE_FLAG, "1");

        // �O���o������:�o�^��ʂ�
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JM,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 
      }

    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
