/*============================================================================
* ファイル名 : XxcsoSpDecisionPropertyUtils
* 概要説明   : 自販機設置契約情報登録表示属性プロパティ設定ユーティリティクラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-28 1.0  SCS柳平直人  新規作成
* 2009-02-16 1.1  SCS柳平直人  [CT1-008]BM指定チェックボックス不正対応
* 2010-02-09 1.2  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCreateInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCreateInitVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoLoginUserAuthorityVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoLoginUserAuthorityVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 自販機設置契約情報登録表示属性プロパティ設定ユーティリティクラス。
 * @author  SCS柳平直人
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistPropertyUtils 
{
  /*****************************************************************************
   * 表示属性プロパティ設定
   * @param pageRdrVo ページ属性設定ビューインスタンス
   * @param mngVo     契約管理テーブル情報ビューインスタンス
   * @param createVo  初期表示情報取得ビューインスタンス
   *****************************************************************************
   */
  public static void setAttributeProperty(
    XxcsoPageRenderVOImpl                pageRdrVo
   ,XxcsoLoginUserAuthorityVOImpl        userAuthVo
   ,XxcsoContractManagementFullVOImpl    mngVo
   ,XxcsoContractCreateInitVOImpl        createVo
  )
  {
    // データ行取得
    XxcsoPageRenderVORowImpl pageRdrRow
      = (XxcsoPageRenderVORowImpl) pageRdrVo.first();

    XxcsoLoginUserAuthorityVORowImpl userAuthRow
      = (XxcsoLoginUserAuthorityVORowImpl) userAuthVo.first();

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first(); 

    XxcsoContractCreateInitVORowImpl  createRow
      = (XxcsoContractCreateInitVORowImpl) createVo.first();

    // ////////////////////
    // 自動販売機設置契約書データ 登録判別
    // ////////////////////
    if ( mngRow.getContractManagementId().intValue() > 0 )
    {
      // 登録データ時はPDF作成ボタン表示
      pageRdrRow.setPrintPdfButtonRender(Boolean.TRUE);
    }
    else
    {
      pageRdrRow.setPrintPdfButtonRender(Boolean.FALSE);
    }

    // ////////////////////
    // ステータス判別
    // ////////////////////
    // ステータスが確定済みの場合
    if ( isStatusDecision( mngRow.getStatus() ) )
    {
      setPageSecurityNone(pageRdrRow);
    }
    // 上記以外のステータスの場合
    else
    {
// 2010-02-09 [E_本稼動_01538] Mod Start
      String ContractNumber1 = mngRow.getContractNumber();
      String ContractNumber2 = mngRow.getLatestContractNumber();
      // 契約書新旧判定
      if (! isContractNumberCheck(mngRow.getContractNumber(),
                                  mngRow.getLatestContractNumber()
                                 )
         )
      {
        setPageSecurityNone(pageRdrRow);
      }
      else
      {
// 2010-02-09 [E_本稼動_01538] Mod End
        // ログインユーザー権限によるページ属性設定
        if (userAuthRow != null)
        {
          String userAuth = userAuthRow.getUserAuthority();
          // 権限なし
          if (XxcsoContractRegistConstants.AUTH_NONE.equals(userAuth))
          {
            setPageSecurityNone(pageRdrRow);
          }
          // 獲得営業員または売上担当営業員
          else if (XxcsoContractRegistConstants.AUTH_ACCOUNT.equals(userAuth))
          {
            setPageSecurityAccount(pageRdrRow);
          }
          // 拠点長
          else if (XxcsoContractRegistConstants.AUTH_BASE_LEADER.equals(userAuth))
          {
            setPageSecurityBaseLeader(pageRdrRow);
          }
          // 上記以外は想定外のため、編集不可状態にする
          else
          {
            setPageSecurityNone(pageRdrRow);
          }
        }
        else
        {
          setPageSecurityNone(pageRdrRow);
        }
// 2010-02-09 [E_本稼動_01538] Mod Start
      }
// 2010-02-09 [E_本稼動_01538] Mod End
    }

    // /////////////////////
    // 振込日・締め日情報リージョン編集可否設定
    // /////////////////////
    String lineCount = createRow.getLineCount();
    if ( ! "0".equals(lineCount) )
    {
      pageRdrRow.setPayCondInfoEnabled( Boolean.TRUE);
      pageRdrRow.setPayCondInfoDisabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setPayCondInfoEnabled( Boolean.FALSE);
      pageRdrRow.setPayCondInfoDisabled(Boolean.TRUE);
    }

    // ※設定後に再度設定判定（ページ自体のセキュリティ考慮）
    if ( pageRdrRow.getPayCondInfoViewRender().booleanValue() )
    {
      pageRdrRow.setPayCondInfoEnabled(Boolean.FALSE);
      if ( pageRdrRow.getPayCondInfoDisabled().booleanValue() ) 
      {
        pageRdrRow.setPayCondInfoViewRender( Boolean.FALSE );
      }
    }

    // /////////////////////
    // BM1指定チェックボックス
    // /////////////////////
    if ( isBmCheck(createRow.getBm1SpCustId(), createRow.getBm1PaymentType() ) )
    {
      pageRdrRow.setBm1ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_ON
      );
      pageRdrRow.setBm1Enabled( Boolean.TRUE);
      pageRdrRow.setBm1Disabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setBm1ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_OFF
      );
      pageRdrRow.setBm1Enabled( Boolean.FALSE);
      pageRdrRow.setBm1Disabled(Boolean.TRUE);
    }

    // /////////////////////
    // BM2指定チェックボックス
    // /////////////////////
    if ( isBmCheck(createRow.getBm2SpCustId(), createRow.getBm2PaymentType() ) )
    {
      pageRdrRow.setBm2ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_ON
      );
      pageRdrRow.setBm2Enabled( Boolean.TRUE);
      pageRdrRow.setBm2Disabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setBm2ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_OFF
      );
      pageRdrRow.setBm2Enabled( Boolean.FALSE);
      pageRdrRow.setBm2Disabled(Boolean.TRUE);
    }

    // /////////////////////
    // BM3指定チェックボックス
    // /////////////////////
    if ( isBmCheck(createRow.getBm3SpCustId(), createRow.getBm3PaymentType() ) )
    {
      pageRdrRow.setBm3ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_ON
      );
      pageRdrRow.setBm3Enabled( Boolean.TRUE);
      pageRdrRow.setBm3Disabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setBm3ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_OFF
      );
      pageRdrRow.setBm3Enabled( Boolean.FALSE);
      pageRdrRow.setBm3Disabled(Boolean.TRUE);
    }

    // /////////////////////
    // オーナー変更チェックボックス設定
    // /////////////////////
    String installCode = mngRow.getInstallCode();
    if ( installCode == null || "".equals(installCode) )
    {
      pageRdrRow.setOwnerChangeFlag(
        XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_OFF
      );
    }
    else
    {
      pageRdrRow.setOwnerChangeFlag(
        XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON
      );
    }
    // 表示属性設定用にfirePartialAction時と同様のメソッドを呼ぶ
    setAttributeOwnerChange(pageRdrVo);

  }

  /*****************************************************************************
   * オーナー変更プロパティ設定
   * @param pageRdrVo ページ属性設定ビューインスタンス
   *****************************************************************************
   */
  public static void setAttributeOwnerChange(
    XxcsoPageRenderVOImpl pageRdrVo
  )
  {
    // 表示属性用VO
    XxcsoPageRenderVORowImpl pageRdrRow
      = (XxcsoPageRenderVORowImpl) pageRdrVo.first();

    if ( isOwnerChangeFlagChecked( pageRdrRow.getOwnerChangeFlag() ) )
    {
      pageRdrRow.setOwnerChangeRender(Boolean.TRUE);
    }
    else
    {
      pageRdrRow.setOwnerChangeRender(Boolean.FALSE);
    }
  }

  /*****************************************************************************
   * ページセキュリティ設定(営業員の利用)
   * @param pageRdrVo ページ属性設定ビューインスタンス
   *****************************************************************************
   */
  private static void setPageSecurityAccount(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // ページ         :編集可能
    pageRdrRow.setRegionViewRender(Boolean.FALSE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.FALSE);
    pageRdrRow.setRegionInputRender(Boolean.TRUE);
    // 保存ボタン     :押下可能
    pageRdrRow.setApplyButtonRender(Boolean.TRUE);
    // 確定ボタン     :押下不可
    pageRdrRow.setSubmitButtonRender(Boolean.FALSE);
  }

  /*****************************************************************************
   * ページセキュリティ設定(拠点長)
   * @param pageRdrVo ページ属性設定ビューインスタンス
   *****************************************************************************
   */
  private static void setPageSecurityBaseLeader(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // ページ         :編集可能
    pageRdrRow.setRegionViewRender(Boolean.FALSE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.FALSE);
    pageRdrRow.setRegionInputRender(Boolean.TRUE);
    // 保存ボタン     :押下可能
    pageRdrRow.setApplyButtonRender(Boolean.TRUE);
    // 確定ボタン     :押下可能
    pageRdrRow.setSubmitButtonRender(Boolean.TRUE);
  }
  
  /*****************************************************************************
   * ページセキュリティ設定(確定時)
   * @param pageRdrVo ページ属性設定ビューインスタンス
   *****************************************************************************
   */
  private static void setPageSecurityStatusFix(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // ページ         :編集不可
    pageRdrRow.setRegionViewRender(Boolean.TRUE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.TRUE);
    pageRdrRow.setRegionInputRender(Boolean.FALSE);
    // 保存ボタン     :押下不可
    pageRdrRow.setApplyButtonRender(Boolean.FALSE);
    // 確定ボタン     :押下不可
    pageRdrRow.setSubmitButtonRender(Boolean.FALSE);
  }
  

  /*****************************************************************************
   * ページセキュリティ設定(編集不可の参照状態)
   * @param pageRdrVo ページ属性設定ビューインスタンス
   * @return boolean true:ON false:OFF
   *****************************************************************************
   */
  private static void setPageSecurityNone(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // ページ         :編集不可
    pageRdrRow.setRegionViewRender(Boolean.TRUE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.TRUE);
    pageRdrRow.setRegionInputRender(Boolean.FALSE);

    // 保存ボタン     :押下不可
    pageRdrRow.setApplyButtonRender(Boolean.FALSE);
    // 確定ボタン     :押下不可
    pageRdrRow.setSubmitButtonRender(Boolean.FALSE);
    // PDF作成ボタン  :押下不可
    pageRdrRow.setPrintPdfButtonRender(Boolean.FALSE);
  }

  /*****************************************************************************
   * 契約管理ステータス確定済み判定
   * @param  status 契約管理テーブル.ステータス
   * @return boolean true:確定済み false:確定済み以外
   *****************************************************************************
   */
  private static boolean isStatusDecision(String status)
  {
    return XxcsoContractRegistConstants.STS_FIX.equals(status);
  }

  /*****************************************************************************
   * オーナー変更チェックボックスチェック判定
   * @param  ownerChangeFlag チェックボックスValue
   * @return boolean true:ON false:OFF
   *****************************************************************************
   */
  private static boolean isOwnerChangeFlagChecked(String ownerChangeFlag)
  {
    return XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
            ownerChangeFlag
           );
  }

  /*****************************************************************************
   * BM指定チェックボックスチェック判定
   * @param  spCustId      SP専決顧客ID
   * @param  bmPaymentType BM支払区分
   * @return boolean       true:チェックをON false:チェックをOFF
   *****************************************************************************
   */
  private static boolean isBmCheck(
    Number spCustId
   ,String bmPaymentType)
  {
    boolean retVal = false;

    if ( spCustId != null)
    {
      if (XxcsoContractRegistConstants.BM_PAYMENT_TYPE5.equals(bmPaymentType))
      {
        retVal = false;
      }
      else
      {
        retVal = true;
      }
    }
    return retVal;
  }

// 2010-02-09 [E_本稼動_01538] Mod Start
  /*****************************************************************************
   * 契約書新旧判定
   * @param  ContractNumber1 契約書番号（現在）
   * @param  ContractNumber2 契約書番号（最新）
   * @return boolean         true:新契約書 false:旧契約書
   *****************************************************************************
   */
  private static boolean isContractNumberCheck(
    String ContractNumber1
   ,String ContractNumber2)
  {
    boolean retVal = false;

    if ( ContractNumber1 == null)
    {
      return true;
    }
    if ( ContractNumber2 == null)
    {
      return true;
    }
    // 最新の契約書の場合
    if ( ContractNumber1.equals(ContractNumber2))
    {
      retVal = true;
    }
    else
    {
      retVal = false;
    }
    return retVal;
  }
// 2010-02-09 [E_本稼動_01538] Mod End


}