/*============================================================================
* �t�@�C���� : XxinvFileUploadCreateCO
* �T�v����   : CSV�t�@�C���A�b�v���[�h�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-23 1.0  ������j     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv990001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

import oracle.cabo.ui.data.DataObject;


/**
 * �t�@�C���A�b�v���[�h�R���g���[���B
 * @author  ORACLE �����@��j
 * @version 1.0
 */
public class XxinvFileUploadCreateCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header: /cvsrepo/itoen/oracle/apps/xxinv/xxinv990001j/webui/XxinvFileUploadCreateCO.java,v 1.3 2008/02/21 04:51:01 usr3149 Exp $";
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
    // �u���E�U�u�߂�v�{�^���̑Ή�
    if (!pageContext.isBackNavigationFired(false))
    {
      TransactionUnitHelper.startTransactionUnit(pageContext, 
                                                XxinvConstants.TXN_XXINV990001J);
      // �p�����[�^�擾(�t�@�C�����������R�[�h)
      String contentType = pageContext.getParameter(XxinvConstants.XXINV990001J_PARAM);

      if (contentType == null)
      {
        // �V�X�e���G���[
        // �ݒ�̕s���ɂ���Ĕ�������G���[�B�G���[��ʂɑJ�ڂ�����B
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      // �A�v���P�[�V�������W���[���̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      String meaning = null;
      try {
        // �Q�ƃ^�C�v���R���J�����g���̂���уt�H�[�}�b�g�p�^�[�����擾����B
        Serializable[] params = {XxinvConstants.LOOKUP_TYPE, contentType};
        meaning = (String)am.invokeMethod("getLookUpValue", params);
        // �i�[�p���R�[�h�쐬
        am.invokeMethod("createXxinvMrpFileUlInterfaceRec");
      } catch (OAException ex) 
      {
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
        // DB�G���[�����������ꍇ�́A�G���[��ʂɑJ�ڂ���B
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      // �w�b�_�[���ڃ^�C�g��
      OAPageLayoutBean plRN = (OAPageLayoutBean)webBean;
      // Window Title����уy�[�W���̂̐ݒ�B
      StringBuffer dispBuf = new StringBuffer();
      dispBuf.append(XxinvConstants.DISP_TEXT);
      dispBuf.append(meaning);
      plRN.setTitle(dispBuf.toString());
      plRN.setWindowTitle(dispBuf.toString());

    } else
    {
      // �u���E�U�u�߂�v�{�^���ɑΉ�
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, 
                                                             XxinvConstants.TXN_XXINV990001J, 
                                                             true))
      {
        // �߂�{�^������������Ă���ꍇ�̏����B
        OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
    }
  } // end processRequest

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    // ApplicationModule�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    // �K�p�{�^���̔��f
    if (pageContext.getParameter("Apply") != null)
    {
      // �R���e���g�^�C�v�̎擾
      String contentType = pageContext.getParameter("LookupCode");
       // �R���J�����g�v���O�������̂̎擾
      String programName = pageContext.getParameter("Description");
      // �t�@�C�����̂̎擾
      String fileName = pageContext.getParameter("FileData");
      if (fileName == null || programName == null || contentType == null)
      {
        // �t�@�C�������w�肳��Ă��Ȃ��B
        throw new OAException(XxcmnConstants.APPL_XXINV,
                              "APP-XXINV-10048",
                              null,
                              OAException.ERROR,
                              null);
      }
      // �t�@�C�����̎w��̗L�����`�F�b�N����B
      DataObject data = (DataObject)pageContext.getNamedDataObject("FileData");
      if (data == null)
      {
        // ���[���o�b�N����B
        am.invokeMethod("rollbackXxinvMrpFileUlInterface");
        throw new OAException(XxcmnConstants.APPL_XXINV,
                              "APP-XXINV-10048",
                              null,
                              OAException.ERROR,
                              null);
      }
      // �����ݒ�
      Serializable params[] = {fileName, contentType};
      // �����^�ݒ�
      Class[] parameterTypes = {String.class, String.class};
      // �߂�l��`
      long retVal = 0;
      try {
        // VO�ɐݒ�B
        am.invokeMethod("setUlFileInfo", params, parameterTypes);
        // �R�~�b�g�B
        am.invokeMethod("apply");
        // �R���J�����g���N������B
        params = new Serializable[] {programName, contentType};
        Serializable[] returnObj = {am.invokeMethod("concRun", params)};
        retVal = ((Long)returnObj[0]).longValue();
      } catch (OAException ex) 
      {
        // ���[���o�b�N����B
        am.invokeMethod("rollbackXxinvMrpFileUlInterface");
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
        // DB�G���[�����������ꍇ�́A�G���[��ʂɑJ�ڂ���B
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      if (retVal == 0)
      {
        TransactionUnitHelper.endTransactionUnit(pageContext, 
          XxinvConstants.TXN_XXINV990001J);
        // �R���J�����g���N���ł��Ȃ��ꍇ�̏������L�q����B
        MessageToken[] tokens = { new MessageToken("PROGRAM", programName)};
        OAException ex1 = new OAException(XxcmnConstants.APPL_XXINV,
                                          "APP-XXINV-10005",
                                          tokens,
                                          OAException.ERROR,
                                          null);
        // �G���[���b�Z�[�W��ݒ肷��B
        pageContext.putDialogMessage(ex1);
        HashMap map = new HashMap();
        map.put(XxinvConstants.XXINV990001J_PARAM, contentType);
        // ����y�[�W�֑J�ڂ���B
        pageContext.forwardImmediately(
          APPLICATION_JSP + "?page=/itoen/oracle/apps/xxinv/xxinv990001j/webui/XxinvFileUploadPG",
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          map,
          true, // retain AM 
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

      } else
      {
        // �R�~�b�g�B
        am.invokeMethod("apply");
      }
      TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
      // �������b�Z�[�W�쐬
      MessageToken[] tokens = { new MessageToken("PROGRAM", programName),
                                new MessageToken("ID",      String.valueOf(retVal))};
      OAException confirmMess = new OAException(XxcmnConstants.APPL_XXINV,
                                                "APP-XXINV-10006",
                                                tokens,
                                                OAException.CONFIRMATION,
                                                null);
      pageContext.putDialogMessage(confirmMess);
      HashMap map = new HashMap();
      map.put(XxinvConstants.XXINV990001J_PARAM, contentType);
      // ����y�[�W�ɑJ�ڂ���B
      pageContext.forwardImmediately(
        APPLICATION_JSP + "?page=/itoen/oracle/apps/xxinv/xxinv990001j/webui/XxinvFileUploadPG",
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        map,
        true, // retain AM
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

    } else if (pageContext.getParameter("Cancel") != null)
    {
      TransactionUnitHelper.endTransactionUnit(pageContext,
                                               XxinvConstants.TXN_XXINV990001J);
      // ���[���o�b�N����B
      am.invokeMethod("rollbackXxinvMrpFileUlInterface");
      // �z�[���֑J�ڂ���B
      pageContext.forwardImmediately(XxcmnConstants.URL_OAHOMEPAGE,
                                     GUESS_MENU_CONTEXT,
                                     null,
                                     null,
                                     false, // Do not retain AM
                                     ADD_BREAD_CRUMB_NO);
    }
  } // end processFormRequest
}
