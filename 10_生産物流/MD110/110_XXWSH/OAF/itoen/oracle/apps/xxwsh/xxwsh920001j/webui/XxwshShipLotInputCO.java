/*============================================================================
* �t�@�C���� : XxwshShipLotInputCO
* �T�v����   : ���o�׎��у��b�g���͉��(�o�׎���)�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

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
/***************************************************************************
 * ���o�׎��у��b�g���͉��(�o�׎���)�R���g���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxwshShipLotInputCO extends XxcmnOAControllerImpl
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
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �`�F�b�N�{�^�����������ꂽ�ꍇ
      if ((pageContext.getParameter("Check") != null) ||
          (pageContext.getParameter("Check1") != null)) 
      {
        // �������s��Ȃ��B

      // �K�p�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Go") != null)) 
      {
        // �������s��Ȃ�

      // �_�C�A���O��ʂ�NO�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("No") != null)) 
      {
        // �������s��Ȃ�

      // �_�C�A���O��ʂ�YES�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Yes") != null)) 
      {
        // �o�^����
        am.invokeMethod("entryShipData");
        
      // �����\���̏ꍇ
      } else
      {
        // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
        TransactionUnitHelper.startTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920001J);

        // �p�����[�^�擾      
        HashMap searchParams = new HashMap();
        searchParams.put("orderLineId",      pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID));           // �󒍖��׃A�h�I��ID
        searchParams.put("callPictureKbn",   pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN));  // �ďo��ʋ敪
        searchParams.put("headerUpdateDate", pageContext.getParameter(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE));// �w�b�_�X�V����
        searchParams.put("lineUpdateDate",   pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE));  // ���׍X�V����
        searchParams.put("exeKbn",           pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN));           // �N���敪
        searchParams.put("recordTypeCode",   XxwshConstants.RECORD_TYPE_DELI);                                      // ���R�[�h�^�C�v 20:�o�Ɏ���

        // �����ݒ�
        Serializable params[] = { searchParams };
        // �����^�ݒ�
        Class[] parameterTypes = { HashMap.class };
        // �����������s
        am.invokeMethod("initialize", params, parameterTypes);
      }
            
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwshConstants.TXN_XXWSH920001J, true))
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

    try
    {     
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
     
      // �s�}���{�^���������ꂽ�ꍇ
      if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �s�ǉ��������s
        am.invokeMethod("addRow");

      // �x���w����ʂ֖߂�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Return") != null) 
      {
        String callPictureKbn = pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN); // �ďo��ʋ敪
        String exeKbn         = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);          // �N���敪
        String url            = null;

        // �˗�No�擾
        Serializable params[] = { pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID) };
        String reqNo          = (String)am.invokeMethod("getReqNo", params); // �˗�No
        
        // URL����
        // �ďo��ʋ敪��2:�x���w���쐬��ʂ̏ꍇ
        if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO440001JL; // �x���w���쐬���׉��          

        // �ďo��ʋ敪��4:�o�Ɏ��щ�ʂ̏ꍇ
        } else if (XxwshConstants.CALL_PIC_KBN_DELI.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO441001JL; // �o�Ɏ��ѓ��͖��׉��

        // �ďo��ʋ敪��5:���Ɏ��щ�ʂ̏ꍇ
        } else if (XxwshConstants.CALL_PIC_KBN_STOC.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO442001JL; // ���Ɏ��ѓ��͖��׉��

        // �ďo��ʋ敪��6:�x���ԕi��ʂ̏ꍇ
        } else if (XxwshConstants.CALL_PIC_KBN_RETURN.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO443001JL; // �x���ԕi���׉��
        }
        
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,  exeKbn); // �N���敪
        pageParams.put(XxwshConstants.URL_PARAM_REQ_NO,   reqNo);  // �˗�No

        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920001J);
          
        // �x���w����ʂ�
        pageContext.setForwardURL(
          url,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // �`�F�b�N�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Check") != null) ||
                  (pageContext.getParameter("Check1") != null)) 
      {
        // ���b�g�`�F�b�N�������s
        am.invokeMethod("checkLot");

      // �K�p�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Go") != null)
      {
        // ���b�g�`�F�b�N�������s
        am.invokeMethod("checkLot");
        
        // �G���[�`�F�b�N�������s
        String entryFlag = (String)am.invokeMethod("checkError");

        // �����Ώۍs������ꍇ�A�������s
        if ("1".equals(entryFlag))
        {
          // �x���`�F�b�N�������s
          HashMap msg = (HashMap)am.invokeMethod("checkWarning");

          String[] lotRevErrFlg     = (String[])msg.get("lotRevErrFlg");     // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
          String[] minusErrFlg      = (String[])msg.get("minusErrFlg");      // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O 
          String[] exceedErrFlg     = (String[])msg.get("exceedErrFlg");     // �����\�݌ɐ����߃`�F�b�N�G���[�t���O
          String[] itemName         = (String[])msg.get("itemName");         // �i�ږ�
          String[] lotNo            = (String[])msg.get("lotNo");            // ���b�gNo
          String[] delivery         = (String[])msg.get("delivery");         // �o�א�(�R�[�h)
          String[] revDate          = (String[])msg.get("revDate");          // �t�]���t
          String[] manufacturedDate = (String[])msg.get("manufacturedDate"); // �����N����
          String[] koyuCode         = (String[])msg.get("koyuCode");         // �ŗL�L��
          String[] stock            = (String[])msg.get("stock");            // �莝����
          String[] warehouseName    = (String[])msg.get("warehouseName");    // �ۊǏꏊ

          // �_�C�A���O��ʕ\���p���b�Z�[�W
          StringBuffer pageHeaderText = new StringBuffer(100);

          for(int i = 0 ; i < lotRevErrFlg.length ; i++)
          {
            // ���b�g�t�]�h�~�`�F�b�N�ŃG���[�̏ꍇ
            if (XxcmnConstants.STRING_Y.equals(lotRevErrFlg[i]))
            {
              // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
              XxcmnUtility.newLineAppend(pageHeaderText);

              // ���b�g�t�]�h�~�x�����b�Z�[�W�擾
              MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_ITEM,     itemName[i]),
                                        new MessageToken(XxwshConstants.TOKEN_LOT,      lotNo[i]),
                                        new MessageToken(XxwshConstants.TOKEN_LOCATION, delivery[i]),
                                        new MessageToken(XxwshConstants.TOKEN_REVDATE,  revDate[i])};              
              pageHeaderText.append(
                pageContext.getMessage(
                  XxcmnConstants.APPL_XXWSH, 
                  XxwshConstants.XXWSH33301,
                  tokens));
            }

            // �}�C�i�X�݌Ƀ`�F�b�N�ŃG���[�̏ꍇ
            if (XxcmnConstants.STRING_Y.equals(minusErrFlg[i]))
            {
              // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
              XxcmnUtility.newLineAppend(pageHeaderText);

              // �}�C�i�X�݌Ƀ`�F�b�N�x�����b�Z�[�W�擾
              MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_ITEM,  itemName[i]),
                                        new MessageToken(XxcmnConstants.TOKEN_LOT,   lotNo[i]),
                                        new MessageToken(XxcmnConstants.TOKEN_DATE,  manufacturedDate[i]),
                                        new MessageToken(XxcmnConstants.TOKEN_MARK,  koyuCode[i]),
                                        new MessageToken(XxcmnConstants.TOKEN_STOCK, stock[i])};
              pageHeaderText.append(
                pageContext.getMessage(
                  XxcmnConstants.APPL_XXCMN, 
                  XxcmnConstants.XXCMN00026,
                  tokens));
            }

            // �����\�݌ɐ����߃`�F�b�N�ŃG���[�̏ꍇ
            if (XxcmnConstants.STRING_Y.equals(exceedErrFlg[i]))
            {
              // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
              XxcmnUtility.newLineAppend(pageHeaderText);

              // �����\�݌ɐ����߃`�F�b�N�x�����b�Z�[�W�擾
              MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_LOCATION,  warehouseName[i]),
                                        new MessageToken(XxcmnConstants.TOKEN_ITEM,      itemName[i]),
                                        new MessageToken(XxcmnConstants.TOKEN_LOT,       lotNo[i])};
              pageHeaderText.append(
                pageContext.getMessage(
                  XxcmnConstants.APPL_XXCMN, 
                  XxcmnConstants.XXCMN10110,
                  tokens));
            }
          }

          // �x�����b�Z�[�W�̂���ꍇ�A�_�C�A���O��\��
          if (pageHeaderText.length() > 0)
          {
            // ���C�����b�Z�[�W�쐬 
            MessageToken[] mainTokens = new MessageToken[1];
            mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, pageHeaderText.toString());

            OAException mainMessage = new OAException(
                                            XxcmnConstants.APPL_XXCMN,
                                            XxcmnConstants.XXCMN00025,
                                            mainTokens);
                                            
            // �_�C�A���O���b�Z�[�W��\��
            XxcmnUtility.createDialog(
              OAException.CONFIRMATION,
              pageContext,
              mainMessage,
              null,
              XxwshConstants.URL_XXWSH920001J_1,
              XxwshConstants.URL_XXWSH920001J_1,
              "Yes",
              "No",
              "Yes",
              "No",
              null);          
          }
        
          // �o�^����
          am.invokeMethod("entryShipData"); 
        }
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}

