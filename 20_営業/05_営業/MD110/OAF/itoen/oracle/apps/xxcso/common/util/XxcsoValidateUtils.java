/*============================================================================
* ファイル名 : XxcsoValidateUtils
* 概要説明   : 【アドオン：営業・営業領域】共通検証関数クラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS小川浩    新規作成
* 2009-06-15 1.1  SCS柳平直人  [ST障害T1_1068]禁則文字チェックリスト削除
* 2009-09-25 1.2  SCS阿部大輔  [I_E_534,I_E_548]電話番号のハイフン対応
* 2022-04-04 1.3  SCSK二村悠香 [E_本稼動_18060]自販機顧客別利益管理
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;

/*******************************************************************************
 * アドオン：共通検証関数クラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoValidateUtils 
{
  private List   illegalStringList   = new ArrayList();
  private String enableNumberString  = "01234567890,.";
  private static XxcsoValidateUtils _instance = null;

  /*****************************************************************************
   * 必須チェック
   * @param errorList           エラーリスト
   * @param object              チェック対象数字
   * @param columnName          項目名
   * @param columnIndex         行番号
   * @return List               追加されたエラーリスト
   *****************************************************************************
   */
  public List requiredCheck(
    List    errorList
   ,Object  object
   ,String  columnName
   ,int     columnIndex
  )
  {
    if ( object == null )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00005
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00403
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }

      errorList.add(error);
    }
    else
    {
      if ( object instanceof String )
      {
        if ( "".equals(((String)object).trim()) )
        {
          OAException error = null;
          
          if ( columnIndex == 0 )
          {
             error = XxcsoMessage.createErrorMessage(
                       XxcsoConstants.APP_XXCSO1_00005
                      ,XxcsoConstants.TOKEN_COLUMN
                      ,columnName
                     );
          }
          else
          {
            error = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00403
                     ,XxcsoConstants.TOKEN_COLUMN
                     ,columnName
                     ,XxcsoConstants.TOKEN_INDEX
                     ,String.valueOf(columnIndex)
                    );
          }
          errorList.add(error);
        }
      }
    }
    return errorList;
  }

  /*****************************************************************************
   * 入力された数字が指定の書式にあっているかを確認する
   * @param errorList           エラーリスト
   * @param checkString         チェック対象文字
   * @param columnName          項目名
   * @param columnIndex         行番号
   * @return List               追加されたエラーリスト
   *****************************************************************************
   */
  public List checkIllegalString(
    List   errorList
   ,String checkString
   ,String columnName
   ,int    columnIndex
  )
  {
    if ( checkString == null || "".equals(checkString.trim()) )
    {
      return errorList;
    }
    
    StringBuffer tokenStrings = new StringBuffer(100);
    
    for ( int i = 0; i < illegalStringList.size(); i++ )
    {
      String illegalString = (String)illegalStringList.get(i);
      int index = checkString.indexOf(illegalString);
      if ( index < 0 )
      {
        continue;
      }
      tokenStrings.append(illegalString);
    }

    if ( tokenStrings.length() > 0 )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00320
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_STRINGS
                 ,tokenStrings.toString()
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00404
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_STRINGS
                 ,tokenStrings.toString()
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      errorList.add(error);
    }

    return errorList;
  }

  /*****************************************************************************
   * 入力された数字が指定の書式にあっているかを確認する
   * 1. 必須チェック有か？                    NGの場合、すぐにエラー
   * 2. 数字と[,][.]だけか？                  NGの場合、すぐにエラー
   * 3. [.]の数が最大1つか？                  NGの場合、すぐにエラー
   * 4. [,]が変なところに入っていないか？     NGの場合、すぐにエラー
   * 5. 小数点の桁数チェック                  NGの場合、エラーをスタック
   * 6. 整数の最大桁数チェック                NGの場合、エラーをスタック
   * 7. 0値チェック                           NGの場合、エラーをスタック
   * 8. 後方の[.][,]をチェック                NGの場合、エラーをスタック
   * @param errorList           エラーリスト
   * @param stringNumber        チェック対象数字
   * @param columnName          項目名
   * @param floatDigit          小数点以下の最大桁数
   * @param maxDigit            整数の最大桁数
   * @param minusCheckFlag      マイナスチェック有無  true  : チェック有
   *                                                  false : チェック無
   * @param zeroCheckFlag       0値チェック有無       true  : チェック有
   *                                                  false : チェック無
   * @param requiredCheckFlag   必須チェック有無      true  : チェック有
   *                                                  false : チェック無
   * @param columnIndex         行番号
   * @return List               追加されたエラーリスト
   *****************************************************************************
   */
  public List checkStringToNumber(
    List    errorList
   ,String  stringNumber
   ,String  columnName
   ,int     floatDigit
   ,int     maxDigit
   ,boolean minusCheckFlag
   ,boolean zeroCheckFlag
   ,boolean requiredCheckFlag
   ,int     columnIndex
  )
  {
    //必須チェック
    if ( requiredCheckFlag )
    {
      if ( stringNumber == null || "".equals(stringNumber.trim()) )
      {
        OAException error = null;
        
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00005
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00403
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }
        
        errorList.add(error);
        return errorList;
      }
    }
    else
    {
      if ( stringNumber == null || "".equals(stringNumber.trim()) )
      {
        return errorList;
      }
    }
    
    // 数値に変換できない文字が含まれていないか確認する
    for ( int i = 0; i < stringNumber.length(); i++ )
    {
      char checkChar = stringNumber.charAt(i);
      //先頭の[-]はエラーにしない
      if ( i == 0)
      {
        if ( checkChar == '-' )
        {
          continue;
        }
      }

      int index = enableNumberString.indexOf(checkChar);
      if ( index < 0 )
      {
        OAException error = null;
        
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00009
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00405
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }
        
        errorList.add(error);
        return errorList;
      }
    }

    //後方の[.][,]をチェック
    String dotBackString = ".";
    String commaBackString = ",";

    if ( stringNumber.endsWith(dotBackString) ||
         stringNumber.endsWith(commaBackString) )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00009
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00405
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                );
      }
      
      errorList.add(error);
      return errorList;      
    }
    //先頭が[.]の場合、"0"を付加する
    String convString = stringNumber;
    if ( stringNumber.indexOf(".") == 0 )
    {
      convString = "0".concat(convString);
    }
    // [.]で分割する
    String[] dotSplitString = convString.split("\\.");
    if ( dotSplitString.length > 2 )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00009
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00405
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      
      errorList.add(error);
      return errorList;      
    }

    //[,]で分割する
    String[] commaSplitString = dotSplitString[0].split(",");

    //[,]が１つ以上ある場合チェックを行う
    if ( commaSplitString.length > 1 )
    {
      for (int i = 0 ; i < commaSplitString.length ; i++)
      {
        //1件目
        if ( i == 0 )
        {
          //カンマで始まる文字はエラー
          if ( commaSplitString[i].length() == 0  )
          {
            OAException error = null;
            
            if ( columnIndex == 0 )
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00009
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                      );
            }
            else
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00405
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                       ,XxcsoConstants.TOKEN_INDEX
                       ,String.valueOf(columnIndex)
                      );
            }
            
            errorList.add(error);
            return errorList;
          }
        }
        //2件目以降
        else
        {
          //３の倍数以外の場合はエラー
          int dividing = commaSplitString[i].length() % 3;

          if ( dividing != 0 ||commaSplitString[i].length() == 0 )
          {
            OAException error = null;
            
            if ( columnIndex == 0 )
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00009
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                      );
            }
            else
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00405
                       ,XxcsoConstants.TOKEN_COLUMN
                       ,columnName
                       ,XxcsoConstants.TOKEN_INDEX
                       ,String.valueOf(columnIndex)
                      );
            }
            
            errorList.add(error);
            return errorList;
          }
        }
      }
    }

    //小数の桁数チェック
    String integerString = dotSplitString[0];
    String floatString   = null;
 
    if ( dotSplitString.length == 2 )
    {
      floatString = dotSplitString[1];

      if ( floatDigit < floatString.length() )
      {
        OAException error = null;
        
        if ( floatDigit == 0 )
        {
          if ( zeroCheckFlag )
          {
            if ( columnIndex == 0 )
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00314
                       ,XxcsoConstants.TOKEN_ENTRY
                       ,columnName
                      );
            }
            else
            {
              error = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00408
                       ,XxcsoConstants.TOKEN_ENTRY
                       ,columnName
                       ,XxcsoConstants.TOKEN_INDEX
                       ,String.valueOf(columnIndex)
                      );
            }
          }
          else
          {
            if ( minusCheckFlag )
            {
              if ( columnIndex == 0 )
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00315
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                        );
              }
              else
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00409
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                         ,XxcsoConstants.TOKEN_INDEX
                         ,String.valueOf(columnIndex)
                        );
              }
            }
            else
            {
              if ( columnIndex == 0 )
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00528
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                        );
              }
              else
              {
                error = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00529
                         ,XxcsoConstants.TOKEN_ENTRY
                         ,columnName
                         ,XxcsoConstants.TOKEN_INDEX
                         ,String.valueOf(columnIndex)
                        );
              }
            }
          }
        }
        else
        {
          if ( columnIndex == 0 )
          {
            error = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00249
                     ,XxcsoConstants.TOKEN_COLUMN
                     ,columnName
                     ,XxcsoConstants.TOKEN_DIGIT
                     ,String.valueOf(floatDigit)
                    );
          }
          else
          {
            error = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00406
                     ,XxcsoConstants.TOKEN_COLUMN
                     ,columnName
                     ,XxcsoConstants.TOKEN_DIGIT
                     ,String.valueOf(floatDigit)
                     ,XxcsoConstants.TOKEN_INDEX
                     ,String.valueOf(columnIndex)
                    );
          }
        }
        errorList.add(error);
      }
    }

    //整数の最大桁数チェック
    String word1 = ",";
    String word2 = "";
    String integerStringRep = integerString.replaceAll(word1, word2);
    long longStringRep = Long.parseLong(integerStringRep);
    long maxValue = (long)Math.pow(10, maxDigit);

    if ( ! minusCheckFlag )
    {
      if ( (longStringRep + maxValue) <= 0 )
      {
        OAException error = null;
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00487
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_MIN_VALUE
                   ,String.valueOf((0 - maxValue))
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00488
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_MIN_VALUE
                   ,String.valueOf((0 - maxValue))
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }
        
        errorList.add(error);
      }
    }

    if ( maxValue <= longStringRep )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00248
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_MAX_VALUE
                 ,String.valueOf(maxValue)
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00407
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,columnName
                 ,XxcsoConstants.TOKEN_MAX_VALUE
                 ,String.valueOf(maxValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      
      errorList.add(error);
    }

    double doubleStringRep
      = Double.parseDouble(stringNumber.replaceAll(word1, word2));

    // 0値チェック
    if ( zeroCheckFlag && doubleStringRep == (double)0 )
    {
      OAException error = null;
      
      if ( columnIndex == 0 )
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00314
                 ,XxcsoConstants.TOKEN_ENTRY
                 ,columnName
                );
      }
      else
      {
        error = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00408
                 ,XxcsoConstants.TOKEN_ENTRY
                 ,columnName
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(columnIndex)
                );
      }
      errorList.add(error);
    }

    // マイナス値チェック
    if ( minusCheckFlag && doubleStringRep < (double)0 )
    {
      OAException error = null;

// Ver.1.3 Add Start
      if ( zeroCheckFlag )
      {
// Ver.1.3 Add End
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00126
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00410
                   ,XxcsoConstants.TOKEN_COLUMN
                   ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }
      }
// Ver.1.3 Add Start
      else
      {
        if ( columnIndex == 0 )
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00315
                   ,XxcsoConstants.TOKEN_ENTRY
                   ,columnName
                  );
        }
        else
        {
          error = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00409
                   ,XxcsoConstants.TOKEN_ENTRY
                   ,columnName
                   ,XxcsoConstants.TOKEN_INDEX
                   ,String.valueOf(columnIndex)
                  );
        }        
      }
// Ver.1.3 Add End
      
      errorList.add(error);
    }
    
    return errorList;
  }

  /*****************************************************************************
   * 入力された文字が電話番号として正しいかを確認する
   * @param telNumber           チェック対象文字
   * @return boolean            結果
   *****************************************************************************
   */
  public boolean isTelNumber(
    String   telNumber
  )
  {
    String enableTelString = "1234567890-";
    int sepCount = 0;
    boolean sepFlag = false;

    if ( telNumber == null || "".equals(telNumber.trim()) )
    {
      // NULLの場合は、正常終了
      return true;
    }
    
    for ( int i = 0; i < telNumber.length(); i++ )
    {
      char checkChar = telNumber.charAt(i);

// 2009-09-25 [I_E_534,I_E_548] Add Start
//      if ( ((i == 0) || i == (telNumber.length() - 1)) && (checkChar == '-') )
//      {
//        // 先頭もしくは最後が「-」の場合はNG
//        return false;
//      }
// 2009-09-25 [I_E_534,I_E_548] Add End

      if ( enableTelString.indexOf(checkChar) < 0 )
      {
        // 電話番号として可能な文字でない場合NG
        return false;
      }

// 2009-09-25 [I_E_534,I_E_548] Add Start
//      if ( checkChar == '-' )
//      {
//        sepCount++;
//        if ( sepFlag )
//        {
//          // 「-」が続いていた場合NG
//          return false;
//        }
//        sepFlag = true;
//      }
//      else
//      {
//        sepFlag = false;
//      }
    }

//    if ( sepCount != 2 )
//    {
//      // 「-」が2つない場合NG
//      return false;
//    }
// 2009-09-25 [I_E_534,I_E_548] Add End

    // 全チェックを通ったら正常終了
    return true;
  }

  
  /*****************************************************************************
   * インスタンス取得
   * @param txn OADBTransactionインスタンス
   *****************************************************************************
   */
  public static synchronized XxcsoValidateUtils getInstance(
    OADBTransaction txn
  )
  {
    if ( _instance == null )
    {
      _instance = new XxcsoValidateUtils(txn);
    }
    return _instance;
  }

  /*****************************************************************************
   * コンストラクタ
   * @param txn OADBTransactionインスタンス
   *****************************************************************************
   */
  private XxcsoValidateUtils(
    OADBTransaction txn
  )
  {
// 2009-06-15 [ST障害T1_1068] Del Start
//    illegalStringList.add("~");
//    illegalStringList.add("\\");
//    illegalStringList.add("￣");
//    illegalStringList.add("―");
//    illegalStringList.add("＼");
// 2009-06-15 [ST障害T1_1068] Del End
    illegalStringList.add("～");
// 2009-06-15 [ST障害T1_1068] Del Start
//    illegalStringList.add("∥");
//    illegalStringList.add("…");
//    illegalStringList.add("－");
//    illegalStringList.add("￥");
//    illegalStringList.add("￠");
//    illegalStringList.add("￡");
//    illegalStringList.add("￢");
// 2009-06-15 [ST障害T1_1068] Del End
  }

  /*****************************************************************************
   * デフォルトコンストラクタ
   *****************************************************************************
   */
  private XxcsoValidateUtils()
  {
  }
}